package LIMS2::t::Model::Plugin::Design;
use base qw(Test::Class);
use Test::Most;
use JSON qw( encode_json decode_json );

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Design.pm - test class for LIMS2::Model::Plugin::Design

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

sub all_tests : Test(80) {
    {
        ok my $design = model->c_retrieve_design( { id => 84231 } ), 'retrieve design id=84231';
        isa_ok $design, 'LIMS2::Model::Schema::Result::Design';
        can_ok $design, 'as_hash';
        ok my $h1 = $design->as_hash(), 'as hash, with relations';
        isa_ok $h1, ref {};
        ok $h1->{genotyping_primers}, '...has genotyping primers';
        ok my $h2 = $design->as_hash(1), 'as_hash, suppress relations';
        ok !$h2->{genotyping_primers}, '...no genotyping primers';
        ok my $lf1 = $design->current_primer('LF1'), 'has LF1 primer';
        is $lf1->genotyping_primer_type_id, 'LF1', 'LF1 primer has correct type';
    }

    {
        ok my $designs = model->c_list_assigned_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:94912' } ),
            'list assigned designs by MGI accession';
        isa_ok $designs, ref [];
        ok @{$designs} > 0, '...the list is not empty';
        isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};
    }

    {
        ok my $designs = model->c_list_assigned_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:106032', type => 'conditional' } ),
            'list assigned designs by MGI accession and design type conditional';
        isa_ok $designs, ref [];
        ok @{$designs} > 0, '...the list is not empty';
        isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};
    }

    {
        ok my $designs = model->c_list_assigned_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:1915248', type => 'deletion' } ),
            'list assigned designs by MGI accession and design type deletion';
        is @{$designs}, 0, 'returns no designs';

    }

    {
        ok my $designs = model->c_list_assigned_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:94912', gene_type => 'MGI' } ),
            'list assigned designs by MGI accession, specify id is MGI';
        isa_ok $designs, ref [];
        ok @{$designs} > 0, '...the list is not empty';
        isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};
    }

    {
        ok model->c_search_gene_designs(
            { search_term => 'lbl', page => 1, pagesize => 50, species => 'Mouse' } ),
            'list genes specifying a page and pagesize';
        ok my ( $gene_designs, $pager )
            = model->c_search_gene_designs( { search_term => 'lbl', species => 'Mouse' } ),
            'list matched genes';
        isa_ok $gene_designs, ref [];
        isa_ok $_, 'LIMS2::Model::Schema::Result::GeneDesign' for @{$gene_designs};

        isa_ok $pager, 'DBIx::Class::ResultSet::Pager';

    }

    {
        ok my ($gene_designs) = model->c_search_gene_designs(
            { search_term => 'MGI:109393', gene_type => 'MGI', species => 'Mouse' } ),
            'list matched genes, specify gene type';
        isa_ok $gene_designs, ref [];
        is scalar( @{$gene_designs} ), 1, 'return 1 design';

        ok my ($no_gene_designs) = model->c_search_gene_designs(
            { search_term => 'MGI:109393', gene_type => 'marker-symbol', species => 'Mouse' } ),
            'list matched genes, specify wrong gene type';
        isa_ok $no_gene_designs, ref [];
        is scalar( @{$no_gene_designs} ), 0, 'returns 0 design';
    }

    {
        ok my $designs = model->c_list_candidate_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:94912', type => 'conditional' } ),
            'list candidate designs for MGI accession, gene on -ve strand';
        isa_ok $designs, ref [];
        ok grep( { $_->id == 170606 } @{$designs} ), '...returns the expected design';

        ok my $designs2 = model->c_list_candidate_designs_for_gene(
            { species => 'Mouse', gene_id => 'MGI:99781' } ),
            'list candidate designs by MGI accession, gene on +ve strand';
        is @{$designs2}, 0, 'returns no designs';

        throws_ok {
            model->c_list_candidate_designs_for_gene(
                { species => 'Mouse', gene_id => 'MGI:iiiiii' } )
        }
        'LIMS2::Exception::NotFound', 'throws error for non existant gene';
    }

    {
        ok my $design_types = model->c_list_design_types(), 'can list design types';
    }

    note('Testing the Creation and Deletion of designs');
    {
        my $design_data = build_design_data(84231);

        ok my $new_design = model->c_create_design($design_data), 'can create new design';
        is $new_design->cassette_first, 1,        'default cassette_first value of true';
        is $new_design->id,             99999999, '..and new design has correct id';
        ok my $design_comment = $new_design->comments->first, 'can retrieve design comment';
        is $design_comment->comment_text, 'Test comment', '.. has write comment text';

        ok my $design_gene = $new_design->genes->first, 'can grab gene linked to design';
        is $design_gene->gene_id,      'MGI:1917722', 'design gene is correct';
        is $design_gene->gene_type_id, 'MGI',         'gene type is correct';

        throws_ok {
            model->c_delete_design( { id => 99999999, cascade => 1 } );
        }
        qr/Design 99999999 has been assigned to one or more genes/,
            'can not delete design assigned to one or more genes';

        ok $design_gene->delete, 'can delete design-gene link';

        #link process to new design
        ok my $new_process = model->create_process(
            { type => 'create_di', design_id => 99999999, output_wells => [ { id => 1816 } ] }
            ),
            'can create process linked to new design';

        throws_ok {
            model->c_delete_design( { id => 99999999, cascade => 1 } );
        }
        qr/Design 99999999 has been used in one or more processes/,
            'can not delete design assigned to one or more create_di processes';

        ok model->delete_process( { id => $new_process->id } ), 'delete linked process';

        # Commented out for now as this test dies with "DBD::Pg::st execute failed"
        # when running within a transaction. Can't work out why
        #throws_ok{
        #    model->c_delete_design( { id => 99999999 } )
        #} 'DBIx::Class::Exception', 'can not delete this design without cascade delete enabled';

        ok model->c_delete_design( { id => 99999999, cascade => 1 } ),
            'can delete newly created design';

        throws_ok {
            model->c_delete_design( { id => 11111111 } );
        }
        'LIMS2::Exception::NotFound', 'can not delete non existant design';

        throws_ok {
            model->c_retrieve_design( { id => 99999999 } );
        }
        'LIMS2::Exception::NotFound', '..can not retreive deleted design';

        $design_data->{species} = 'Human';
        $design_data->{id}      = 88888888;
        throws_ok {
            model->c_create_design($design_data);
        }
        qr/Assembly GRCm38 does not belong to species Human/,
            'throws error for species assembly mismatch';
    }

    note('Test adding design parameter data in design creation');
    {
        my $design_data = build_design_data(84231);
        $design_data->{id} = 8888888;
        my $design_parameters = { param_1 => 5, param_2 => 10 };
        $design_data->{design_parameters} = encode_json($design_parameters);

        ok my $new_design = model->c_create_design($design_data), 'can create new design';
        is_deeply decode_json( $new_design->design_parameters ), $design_parameters,
            'design parameters json string is correct';

        ok my $decoded_design_params = $new_design->design_parameters_hash,
            'can decode design parameters data though resultset method';
        is_deeply $decoded_design_params, $design_parameters,
            'design parameters json string is correct';

        $design_data->{design_parameters} = 'this is not json data';
        throws_ok {
            model->c_create_design($design_data);
        }
        qr/design_parameters, is invalid: json/, 'throws error for non json data';
    }

    note('Testing create design oligo');
    {
        my $design_data = build_design_data(84231);

        my $oligos = delete $design_data->{oligos};

        ok my $new_design = model->c_create_design($design_data), 'can create new design';

        my $oligo_data = shift @{$oligos};

        throws_ok {
            model->c_create_design_oligo($oligo_data);
        }
        'LIMS2::Exception::Validation', 'design_id not present';

        $oligo_data->{design_id} = $new_design->id;
        ok my $new_oligo = model->c_create_design_oligo($oligo_data), 'can create new oligo';

    }

    note('Testing creating design without specifying design id, created data or name');
    {
        my $design_data = build_design_data(84231);

        delete $design_data->{oligos};
        delete $design_data->{id};
        delete $design_data->{created_at};
        delete $design_data->{name};

        ok my $new_design = model->c_create_design($design_data), 'can create new design';

        ok $new_design->id, 'new design as a id';
        $new_design->discard_changes;
        ok $new_design->created_at, 'new design has a created at date';
    }

    note('Testing retrieve design oligo');
    {
        ok my $design_oligo
            = model->c_retrieve_design_oligo( { design_id => 81136, oligo_type => 'D5' } ),
            'can retrieve design oligo by design_id and oligo_type';

        is $design_oligo->seq, 'AATATCATGTTTTATGCTGTCTGGAATTTATTGCCTATTTCAAAGCAAAG',
            'oligo has correct sequence';

        ok my $design_oligo2 = model->c_retrieve_design_oligo( { id => 54761 } ),
            'can retrieve design oligo by id';
    }

    note('Testing create design oligo locus');
    {
        ok my $design_oligo_locus = model->c_create_design_oligo_locus(
            {   assembly   => 'NCBIM34',
                chr_name   => 1,
                chr_start  => 10,
                chr_end    => 20,
                chr_strand => 1,
                oligo_type => 'D5',
                design_id  => 81136,
            }
            ),
            'can create design oligo locus';

        ok my $design_oligo = model->c_retrieve_design_oligo( { design_id => 81136, oligo_type => 'D5' } ),
            'can retrieve design_oligo';

        ok my $loci = $design_oligo->loci->find( { assembly_id => 'GRCm38' } ),
            'can find newly created loci attached to oligo';

        throws_ok {
            model->c_create_design_oligo_locus(
                {   assembly   => 'GRCm38',
                    chr_name   => 1,
                    chr_start  => 10,
                    chr_end    => 20,
                    chr_strand => 1,
                    oligo_type => 'D5',
                    design_id  => 999999,
                }
                ),
                'can create design oligo locus';

        }
        'LIMS2::Exception::NotFound', 'unable to create locus for non existant oligo';

    }

    sub build_design_data {
        my $design_id = shift;

        # base new design data on current design data
        ok my $design = model->c_retrieve_design( { id => $design_id } ),
            "retrieve design id=$design_id";

        my $design_data = $design->as_hash;
        $design_data->{id} = 99999999;

        delete $design_data->{assigned_genes};
        delete $design_data->{oligos_fasta};
        $design_data->{genotyping_primers}
            = [ map { delete $_->{id}; delete $_->{species}; delete $_->{locus}; delete $_->{primer_name}; delete $_->{primer_seq}; $_ }
                @{ delete $design_data->{genotyping_primers} } ];

        delete $design_data->{comments};
        $design_data->{comments} = [
            {   category     => 'Other',
                comment_text => 'Test comment',
                created_at   => '2012-05-21T00:00:00',
                created_by   => 'test_user@example.org',
                is_public    => 1,
            }
        ];

        $design_data->{gene_ids} = [ { gene_id => 'MGI:1917722', gene_type_id => 'MGI' } ];

        my $oligos = delete $design_data->{oligos};
        for my $oligo ( @{$oligos} ) {
            delete $oligo->{id};
            $oligo->{loci} = [ delete $oligo->{locus} ];
            delete $oligo->{loci}[0]{species};
        }
        $design_data->{oligos} = $oligos;

        return $design_data;
    }

}

sub design_attempts : Tests(8) {
    my $design_attempt_data = {
        gene_id    => 'FOO',
        status     => 'pending',
        created_by => 'test_user@example.org',
        species    => 'Human',
    };

    my $design_parameters = { param_1 => 5, param_2 => 10 };
    $design_attempt_data->{design_parameters} = encode_json($design_parameters);

    ok my $design_attempt = model->c_create_design_attempt($design_attempt_data), 'can create new design attempt';
    is $design_attempt->gene_id, 'FOO', '.. has correct gene_id';
    is $design_attempt->species_id, 'Human', '.. has correct species_id';

    my $design_attempt_update = {
        id     => $design_attempt->id,
        status => 'fail',
        fail   => encode_json( { reason => 'unknown' } ),
    };
    ok model->c_update_design_attempt( $design_attempt_update ), 'can update design_attempt';

    ok my $design_attempt2 = model->c_retrieve_design_attempt( { id => $design_attempt->id } ),
        'can retrieve a design attempt';
    is $design_attempt2->status, 'fail', '..updated status correctly';

    ok model->c_delete_design_attempt( { id => $design_attempt->id } ), 'can deleted design attempt';

    throws_ok {
        model->c_retrieve_design_attempt( { id => $design_attempt->id } )
    } 'LIMS2::Exception::NotFound', 'can not find deleted design attempt';

}

## use critic

1;

__END__

