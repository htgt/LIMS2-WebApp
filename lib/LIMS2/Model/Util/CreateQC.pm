package LIMS2::Model::Util::CreateQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateQC::VERSION = '0.348';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_or_retrieve_eng_seq
            find_qc_template_with_layout
            build_qc_template_search_params
            create_qc_run_seq_proj
            create_qc_test_result_alignment
            get_qc_run_seq_well_from_alignments
            htgt_api_call
            link_primers_to_qc_run_template
            )
    ]
};

use Log::Log4perl qw( :easy );
use JSON qw( encode_json decode_json );
use Data::Compare qw( Compare );
use List::MoreUtils qw( uniq );
use Hash::MoreUtils qw( slice );
use LIMS2::Exception::Validation;
use LIMS2::Exception::System;
use Try::Tiny;

sub create_or_retrieve_eng_seq {
    my ( $model, $params ) = @_;

    return $model->schema->resultset('QcEngSeq')->find_or_create(
        {   method => $params->{eng_seq_method},
            params => _encode_eng_seq_params( $params->{eng_seq_params} )
        },
        { key => 'qc_eng_seqs_method_params_key' }
    );
}

sub build_qc_template_search_params {
    my ( $params ) = @_;

    if ( defined $params->{id} ) {
        return { 'me.id' => $params->{id} };
    }

    my %search;

    if ( $params->{species} ) {
        $search{'me.species_id'} = $params->{species};
    }

    if ( $params->{name} ) {
        $search{'me.name'} = $params->{name};
    }
    else {
        LIMS2::Exception::System->throw(
            'Can not build qc template search params without a template name' );
    }

    if ( $params->{created_before} ) {
        $search{'me.created_at'} = { '<=', $params->{created_before} };
    }

    if ( $params->{latest} ) {
        if ( $params->{created_before} ) {
            $search{'me.created_at'} = {
                '=' => \[
                    '( select max(created_at) from qc_templates where name = me.name and created_at <= ? )',
                    [ created_at => $params->{created_before} ]
                ]
            };
        }
        else {
            $search{'me.created_at'}
                = { '=' => \['( select max(created_at) from qc_templates where name = me.name )'] };
        }
    }

    return \%search;
}

sub find_qc_template_with_layout {
    my ( $model, $species, $template_name, $template_layout ) = @_;

    my $template_rs = $model->schema->resultset('QcTemplate')->search(
        {
            'me.name'       => $template_name,
            'me.species_id' => $species
        },
        { prefetch => { qc_template_wells => 'qc_eng_seq' } }
    );

    while ( my $template = $template_rs->next ) {
        if ( _qc_template_has_identical_layout( $template, $template_layout ) ) {
            DEBUG("Found existing template with identical layout");
            return $template;
        }
    }

    return;
}

sub pspec__create_qc_run_seq_proj {
    return {
        qc_seq_project_id => { validate => 'non_empty_string' },
        species_id        => { validate => 'existing_species' }
    };
}

sub create_qc_run_seq_proj {
    my ( $model, $qc_run, $params ) = @_;

    my $validated_params = $model->check_params( $params, pspec__create_qc_run_seq_proj );

    my $qc_seq_project = $model->schema->resultset( 'QcSeqProject' )->find_or_create(
        {
            id         => $validated_params->{qc_seq_project_id},
            species_id => $validated_params->{species_id}
        }
    );

    return $qc_run->create_related( qc_run_seq_projects => { qc_seq_project_id => $qc_seq_project->id } );
}

sub pspec__create_qc_test_result_alignment {
    return {
        qc_seq_read_id    => { validate => 'existing_qc_seq_read_id' },
        qc_eng_seq_id     => { validate => 'existing_qc_eng_seq_id' },
        primer_name       => { validate => 'non_empty_string' },
        query_start       => { validate => 'integer' },
        query_end         => { validate => 'integer' },
        query_strand      => { validate => 'strand' },
        target_start      => { validate => 'integer' },
        target_end        => { validate => 'integer' },
        target_strand     => { validate => 'strand' },
        score             => { validate => 'integer' },
        pass              => { validate => 'boolean' },
        features          => { optional => 1 },
        cigar             => { validate => 'cigar_string' },
        op_str            => { validate => 'op_str' },
        alignment_regions => { optional => 1 }
    };
}

sub create_qc_test_result_alignment {
    my ( $model, $params, $qc_test_result ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_qc_test_result_alignment );

    $validated_params->{features} ||= '';

    my $alignment = $model->schema->resultset('QcAlignment')->create(
        {
            qc_run_id => $qc_test_result->qc_run_id, #for duplicate runs
            slice(
                $validated_params, qw( qc_seq_read_id qc_eng_seq_id primer_name
                    query_start query_end query_strand
                    target_start target_end target_strand
                    score pass features cigar op_str )
            )
        }
    );

    for my $region ( @{ $validated_params->{alignment_regions} || [] } ) {
        _create_qc_test_result_alignment_region( $model, $region, $alignment );
    }

    return $alignment;
}

sub pspec__create_qc_test_result_alignment_region {
    return {
        name        => { validate => 'non_empty_string' },
        length      => { validate => 'integer' },
        match_count => { validate => 'integer' },
        query_str   => { validate => 'qc_alignment_seq' },
        target_str  => { validate => 'qc_alignment_seq' },
        match_str   => { validate => 'qc_match_str', trim => 0 },
        pass        => { validate => 'boolean' }
    };
}

#generic function to make a htgt api call, accepting a hashref of user parameters,
#and returning the decoded json content provided by the api page.
sub htgt_api_call {
    my ( $c, $params, $conf_uri_key ) = @_;

    my $content = {};

    #do everythign in a try because if it fails there's no template and you get a useless error
    try {

        die "No URI specified." unless $conf_uri_key;

        my $ua = LWP::UserAgent->new();
        my $qc_conf = Config::Tiny->new();
        $qc_conf = Config::Tiny->read( $ENV{ LIMS2_QC_CONFIG } );

        #add authentication information
        $params->{ username } = $qc_conf->{_}->{ username };
        $params->{ password } = $qc_conf->{_}->{ password };

        my $uri = $qc_conf->{_}->{ $conf_uri_key }; #kill_uri or submit_uri

        die "No QC submission service has been configured. Cannot submit QC job."
            unless $qc_conf;

        #create a http request object sending json
        my $req = HTTP::Request->new( POST => $uri );
        $req->content_type( 'application/json' );
        $req->content( encode_json( $params ) );

        #make the actual request
        my $response = $ua->request( $req );

        die "Request to $uri was not successful. Response: ".$response->status_line."<br/>".$response->as_string
            unless $response->is_success;

        $content = decode_json( $response->content );
    }
    catch {
        $c->stash( error_msg => "Sorry, your HTGT API submission failed with error: $_" );
        return;
    };
    return $content;
}

sub _create_qc_test_result_alignment_region {
    my ( $model, $params, $alignment ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_qc_test_result_alignment_region );

    return $alignment->create_related( qc_alignment_regions => $validated_params );
}

sub get_qc_run_seq_well_from_alignments {
    my ( $model, $qc_run_id, $alignments ) = @_;

    my @qc_seq_read_ids = uniq map { $_->{qc_seq_read_id} } @{$alignments};

    my @wells = $model->schema->resultset('QcRunSeqWell')->search(
        {   'me.qc_run_id'                                => $qc_run_id,
            'qc_run_seq_well_qc_seq_reads.qc_seq_read_id' => { -in => \@qc_seq_read_ids }
        },
        {   join     => 'qc_run_seq_well_qc_seq_reads',
            columns  => ['me.id'],
            distinct => 1
        }
    );


    LIMS2::Exception::Validation->throw(
        {
            message => 'Alignments must belong to exactly one well, have '. scalar (@wells),
            params  => { alignments => $alignments }
        }
    ) unless @wells == 1;

    return shift @wells;
}

sub link_primers_to_qc_run_template{
    my ( $qc_run ) = @_;

    my $primer_filter = { is_validated => 1, is_rejected => [ 0, undef ] };
    foreach my $template_well ($qc_run->qc_template->qc_template_wells){
        if(my $source_well = $template_well->source_well){
            next unless $source_well->plate->type_id eq 'ASSEMBLY';
            my $design = $source_well->design;
            # Find validated genotyping primers for this design and add qc_template_well_genotyping_primers
            foreach my $gt_primer ($design->genotyping_primers($primer_filter)){
                $template_well->create_related(
                    'qc_template_well_genotyping_primers',
                    {
                        qc_run_id => $qc_run->id,
                        genotyping_primer_id => $gt_primer->id,
                    }
                );
            }
            my ($assembly_process) = $source_well->parent_processes;
            my @validated_crispr_primers;

            if($assembly_process->type_id eq 'single_crispr_assembly'){
                my $crispr = $source_well->crispr;
                @validated_crispr_primers = $crispr->crispr_primers->search($primer_filter);
            }
            elsif($assembly_process->type_id eq 'paired_crispr_assembly'){
                my $pair = $source_well->crispr_pair;
                if($pair){
                    @validated_crispr_primers = $pair->crispr_primers->search($primer_filter);
                }
            }

            # FIXME: what about crispr group primers??

            foreach my $primer (@validated_crispr_primers){
                $template_well->create_related(
                    'qc_template_well_crispr_primers',
                    {
                        qc_run_id => $qc_run->id,
                        crispr_primer_id => $primer->id,
                    }
                );
            }
        }
    }

    return;
}

sub _encode_eng_seq_params {
    my ( $eng_seq_params ) = @_;
    return JSON->new->utf8->canonical->encode($eng_seq_params);
}

sub _qc_template_has_identical_layout {
    my ( $template, $wanted_layout ) = @_;

    my %template_layout = map { $_->name => $_->qc_eng_seq_id } $template->qc_template_wells;

    return Compare( \%template_layout, $wanted_layout );
}

1;

__END__
