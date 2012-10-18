#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use DateTime;

my $well_data= test_data( 'well.yaml' );

note( "Testing well EngSeqParam generation");
{
    ok my ($method, $params) = model->generate_well_eng_seq_params({ well_id => 850 }),
        'generate well_eng_seq_params should succeed'; 
}

note( "Testing well creation" );

{
    ok my $well = model->create_well( $well_data->{well_create} ),
        'create_well should succeed';
    isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
    is $well->created_by->name, 'test_user@example.org', 'well has correct created by user';
    is $well->name, 'B01', 'well has correct name';
    is $well->plate->name, 'PCS00177_A', 'well belongs to correct plate';

    ok my $retrieve_well = model->retrieve_well( { id => $well->id } ),
        'retrieve_well by id should succeed';
    is $well->id, $retrieve_well->id, 'has correct id';
}

{
    note( "Testing well retrieve" );
    ok my $well = model->retrieve_well( $well_data->{well_retrieve} ),
        'retrieve_plate by name should succeed';
    isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
    is $well->name, 'B01', 'retrieved correct well';
    is $well->plate->name, 'PCS00177_A', '.. on correct plate';

    note( "Testing create well accepted override" );
    ok my $override = model->create_well_accepted_override( $well_data->{well_accepted_override_create} ),
        'create_well_accepted_override should succeed';
    isa_ok $override, 'LIMS2::Model::Schema::Result::WellAcceptedOverride';
    is $override->accepted, 0, 'override has correct value';
    is $override->well->id, $well->id, 'override belongs to correct well';

    note( "Testing retrieve well accepted override" );
    ok my $well2 = model->retrieve_well($well_data->{well_accepted_override_create}),
        'retrieve created well should succeed';
    ok my $override2 = model->retrieve_well_accepted_override( {well_id => $well2->id} ),
        'retrieve_well_accepted_override should succeed';
    is $override2->well->id, $well2->id, 'retrieved override belongs to correct well';
        
    note( "Testing update well accepted override" );
    ok my $updated_override =  model->update_well_accepted_override( $well_data->{well_accepted_override_update} ),
        'update_well_accepted_override should succeed';
    is $updated_override->accepted, 1, 'override has correct value';

    throws_ok {
        model->update_well_accepted_override( $well_data->{well_accepted_override_update_same} );
    } qr/Well already has accepted override with value TRUE/;

    ok $override->delete, 'can delete override';
}

{
    note( "Testing set_well_assay_complete" );

    my $date_time = DateTime->new(
        year   => 2010,
        month  => 9,
        day    => 12,
        hour   => 10,
        minute => 5,
        second => 7
    );

    my %params = ( %{ $well_data->{well_retrieve} },
                   completed_at => $date_time->iso8601
               );

    ok my $well = model->set_well_assay_complete( \%params ), 'set_well_assay_complete should succeed';

    ok ! $well->accepted, 'well is not automatically accepted';

    is $well->assay_complete, $date_time, 'assay_complete has expected datetime';

    ok model->create_well_qc_sequencing_result(
        {
            well_id         => $well->id,
            valid_primers   => 'LR,PNF,R1R',
            pass            => 1,
            test_result_url => 'http://example.org/some/url/or/other',
            created_by      => 'test_user@example.org'
        }
    ), 'create QC sequencing result';
    
    ok my $qc_seq = model->retrieve_well_qc_sequencing_result( { id => $well->id } ),
        'retrieve_well_qc_sequencing_result should succeed';
    isa_ok $qc_seq, 'LIMS2::Model::Schema::Result::WellQcSequencingResult';
    is $qc_seq->valid_primers, 'LR,PNF,R1R', 'qc valid primers correct';
    is $qc_seq->test_result_url, 'http://example.org/some/url/or/other', 'qc test result url correct';

    $date_time = DateTime->now;

    ok $well = model->set_well_assay_complete( { id => $well->id, completed_at => $date_time->iso8601 } ),
        'set_well_assay_complete should succeed';

    ok $well->accepted, 'well is automatically accepted now that we have a sequencing pass';

    is $well->assay_complete, $date_time, 'assay_complete has expected datetime';
    
    lives_ok {
        model->delete_well_qc_sequencing_result( { id => $well->id } )
    } 'delete well qc sequencing result';
    
    throws_ok{
    	model->retrieve_well_qc_sequencing_result( { id => $well->id } )
    } qr/No WellQcSequencingResult entity found/;
}

{
    note("Testing well dna status create, retrieve and delete");

    throws_ok {
        model->create_well_dna_status( { plate_name => 'MOHFAQ0001_A_2' , well_name => 'D04', pass => 1, created_by => 'test_user@example.org' }  );
    } qr/Well MOHFAQ0001_A_2_D04 already has a dna status of pass/;

    ok my $dna_status = model->retrieve_well_dna_status( { plate_name =>'MOHFAQ0001_A_2', well_name => 'D04' } ), 'can retrieve dna status for well';
    is $dna_status->pass, 1, 'dna status is pass';
    ok my $well = $dna_status->well, '.. can grab well from dna_status';
    is "$well", 'MOHFAQ0001_A_2_D04', '.. and dna_status is for right well';

    lives_ok {
        model->delete_well_dna_status( { plate_name =>'MOHFAQ0001_A_2', well_name => 'D04' } )
    } 'delete well dna status';

    throws_ok {
       model->retrieve_well_dna_status( { plate_name =>'MOHFAQ0001_A_2', well_name => 'D04' } )
    } qr/No WellDnaStatus entity found/;

    ok my $new_dna_status = model->create_well_dna_status( { plate_name => 'MOHFAQ0001_A_2' , well_name => 'D04', pass => 1, created_by => 'test_user@example.org' }  ), 'can create well dna status';
    is $new_dna_status->pass, 1, 'dna status is pass';
    is $well->id, $new_dna_status->well_id , '.. and dna_status is for right well';
}

{
	note("Testing well recombineering result create and retrieve");
	
	ok my $recomb = model->create_well_recombineering_result( $well_data->{well_recombineering_create} ),
	    'create_well_recombineering_result should succeed';
	isa_ok $recomb, 'LIMS2::Model::Schema::Result::WellRecombineeringResult';
	is $recomb->result_type_id, 'pcr_u', 'recombineering result type correct';
	is $recomb->result, 'pass', 'recombineering result correct';
	
	ok my $rec_results = model->retrieve_well_recombineering_results( $well_data->{well_recombineering_create} ),
	    'can retrieve recombineering results by name';
	isa_ok($rec_results, 'ARRAY');
	isa_ok($rec_results->[0], 'LIMS2::Model::Schema::Result::WellRecombineeringResult');    
	
	throws_ok{
		model->create_well_recombineering_result( $well_data->{well_recombineering_create_bad} )
	} qr/is invalid: existing_recombineering_result_type/;
}

{
	note( "Testing well dna quality create and retrieve");
	
	ok my $quality = model->create_well_dna_quality( $well_data->{well_dna_quality_create} ),
	    'create_well_dna_quality should succeed';
	isa_ok $quality, 'LIMS2::Model::Schema::Result::WellDnaQuality';
	is $quality->quality, 'M', 'DNA quality is correct';
	
	ok model->retrieve_well_dna_quality( $well_data->{well_dna_quality_create} ),
	    'retrieve_well_dna_quality should succeed';
    
    throws_ok{
    	model->retrieve_well_dna_quality( { id => 845 } );
    } qr /No WellDnaQuality entity found/;
}

{
    note( "Testing delete_well" );

    lives_ok {
        model->delete_well( { plate_name => 'PCS00177_A', well_name => 'B01' } )
    } 'delete well';
}

done_testing();
