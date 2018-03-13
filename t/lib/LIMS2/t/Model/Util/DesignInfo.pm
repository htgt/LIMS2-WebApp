package LIMS2::t::Model::Util::DesignInfo;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::DesignInfo;

use LIMS2::Test model => { classname => __PACKAGE__ };
use Try::Tiny;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/DesignInfo.pm - test class for LIMS2::Model::Util::DesignInfo

=cut

sub all_tests : Test(158) {

    note('Test Valid Conditional -ve Stranded Design');

    {
        ok my $design = model->c_retrieve_design( { id => 81136 } ), 'can grab design 81136';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->chr_strand, -1, 'strand correct';
        is $di->chr_name,   15, 'chromosome correct';

        # D5 start
        is $di->target_region_start, 53719453, 'correct target region start';

        # U3 end
        is $di->target_region_end, 53720128, 'correct target region end';

        is $di->loxp_start,         53719367, 'correct loxp_start';
        is $di->loxp_end,           53719452, 'correct loxp_end';
        is $di->cassette_start,     53720129, 'correct cassette_start';
        is $di->cassette_end,       53720171, 'correct cassette_end';
        is $di->homology_arm_start, 53715716, 'correct homology_arm_start';
        is $di->homology_arm_end,   53725854, 'correct homology_arm_end';

        ok my $oligos = $di->oligos, 'can grab oligos hash';
        for my $oligo_type (qw( G5 U5 U3 D5 D3 G3 )) {
            ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
        }
    }

    note('Test Valid Conditional +ve Stranded Design');

    {
        ok my $design = model->c_retrieve_design( { id => 39833 } ), 'can grab design 39833';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->chr_strand, 1, 'strand correct';
        is $di->chr_name,   1, 'chromosome correct';

        # U3 start
        is $di->target_region_start, 134595413, 'correct target region start';

        # D5 end
        is $di->target_region_end, 134596081, 'correct target region end';

        is $di->loxp_start,         134596082, 'correct loxp_start';
        is $di->loxp_end,           134596162, 'correct loxp_end';
        is $di->cassette_start,     134595362, 'correct cassette_start';
        is $di->cassette_end,       134595412, 'correct cassette_end';
        is $di->homology_arm_start, 134590486, 'correct homology_arm_start';
        is $di->homology_arm_end,   134601190, 'correct homology_arm_end';

        ok my $oligos = $di->oligos, 'can grab oligos hash';
        for my $oligo_type (qw( G5 U5 U3 D5 D3 G3 )) {
            ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
        }
    }

    note('Test Valid Conditional -ve Stranded Deletion');

    {
        ok my $design = model->c_retrieve_design( { id => 88505 } ), 'can grab design 88505';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->chr_strand, -1, 'strand correct';
        is $di->chr_name,   7,  'chromosome correct';

        # D3 end
        is $di->target_region_start, 122093614, 'correct target region start';

        # U5 start
        is $di->target_region_end, 122096800, 'correct target region end';

        is $di->loxp_start,         undef,     'correct loxp_start';
        is $di->loxp_end,           undef,     'correct loxp_end';
        is $di->cassette_start,     122093615, 'correct cassette_start';
        is $di->cassette_end,       122096799, 'correct cassette_end';
        is $di->homology_arm_start, 122090021, 'correct homology_arm_start';
        is $di->homology_arm_end,   122103023, 'correct homology_arm_end';

        ok my $oligos = $di->oligos, 'can grab oligos hash';
        for my $oligo_type (qw( G5 U5 D3 G3 )) {
            ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
        }
    }

    note('Test Valid Conditional +ve Stranded Deletion');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->chr_strand, 1,  'strand correct';
        is $di->chr_name,   18, 'chromosome correct';

        # U5 end
        is $di->target_region_start, 60956803, 'correct target region start';

        # D3 start
        is $di->target_region_end, 60964117, 'correct target region end';

        is $di->loxp_start,         undef,    'correct loxp_start';
        is $di->loxp_end,           undef,    'correct loxp_end';
        is $di->cassette_start,     60956804, 'correct cassette_start';
        is $di->cassette_end,       60964116, 'correct cassette_end';
        is $di->homology_arm_start, 60951494, 'correct homology_arm_start';
        is $di->homology_arm_end,   60967893, 'correct homology_arm_end';

        ok my $oligos = $di->oligos, 'can grab oligos hash';
        for my $oligo_type (qw( G5 U5 D3 G3 )) {
            ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
        }
    }

    note('Test Getting Info via Design Object');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';
        is $design->chr_name,            18,       'chromosome correct';
        is $design->chr_strand,          1,        'chromosome correct';
        is $design->target_region_start, 60956803, 'correct target region start';
        is $design->target_region_end,   60964117, 'correct target region end';
    }

    note('Test Invalid Design');

    {
        ok my $design = model->c_retrieve_design( { id => 81136 } ), 'can grab design 81136';
        ok my $G5_oligo = model->schema->resultset('DesignOligo')->find(
            {   design_id            => 81136,
                design_oligo_type_id => 'G5',
            }
            ),
            'can grab design 81136 G5 oligo';

        ok my $default_assembly_id = $design->species->default_assembly->assembly_id,
            'can grab designs default assembly';
        ok my $g5_locus
            = $G5_oligo->search_related( 'loci', { assembly_id => $default_assembly_id } )->first,
            'can grab g5 oligos current locus object';

        ok $g5_locus->update( { chr_strand => 1, chr_id => 3172 } ),
            'update G5 locus with incorrect info';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        throws_ok {
            $di->chr_strand;
        }
        qr/Design 81136 oligos have inconsistent strands/,
            'throws error when getting design strand, we have mismatch';

        throws_ok {
            $di->chr_name;
        }
        qr/Design 81136 oligos have inconsistent chromosomes/,
            'throws error when getting design strand, we have mismatch';

    }

    note('Test ensembl adapters');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        isa_ok $di->slice_adaptor,      'Bio::EnsEMBL::DBSQL::SliceAdaptor';
        isa_ok $di->gene_adaptor,       'Bio::EnsEMBL::DBSQL::GeneAdaptor';
        isa_ok $di->transcript_adaptor, 'Bio::EnsEMBL::DBSQL::TranscriptAdaptor';
        isa_ok $di->db_adaptor,         'Bio::EnsEMBL::DBSQL::DBAdaptor';
    }

    note('Test target region slice');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        ok my $slice = $di->target_region_slice, 'can get target region slice';
        isa_ok $slice, 'Bio::EnsEMBL::Slice';

        is $slice->start,           $di->target_region_start, 'slice start is correct';
        is $slice->end,             $di->target_region_end,   'slice end is correct';
        is $slice->seq_region_name, $di->chr_name,            'slice chromosome is correct';
        is $slice->strand,          $di->chr_strand,          'slice strand is correct';
    }

    note('Test target gene');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->target_gene->stable_id, 'ENSMUSG00000024617', 'target gene correct';
    }

    note('Test design with more than one target gene');

    {
        ok my $design = model->c_retrieve_design( { id => 39977 } ), 'can grab design 39977';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->target_gene->stable_id, 'ENSMUSG00000018899', 'target gene correct';
    }

    note('Test MGI Accession ID');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        is $di->get_mgi_accession_id_for_gene( $di->target_gene ), 'MGI:88256',
            'MGI Accession correct',
    }

    note('Test design with target transcript');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        ok my $transcript = $di->target_transcript, 'can get target transcript';
        isa_ok $transcript, 'Bio::EnsEMBL::Transcript';

        is $transcript->stable_id, $design->target_transcript, 'target transcript correct';
    }

    note('Test design without target transcript');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        #make sure we get the right transcript even if one isn't set.
        $design->target_transcript("");

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object without target transcript';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        ok my $transcript = $di->target_transcript, 'can get target transcript';
        isa_ok $transcript, 'Bio::EnsEMBL::Transcript';

        is $transcript->stable_id, 'ENSMUST00000025519', 'target transcript correct';

        $design->discard_changes;    #we dont need to save the empty transcript.
    }

    note('Test floxed exons');

    {
        ok my $design = model->c_retrieve_design( { id => 88512 } ), 'can grab design 88512';

        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';
        isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

        isa_ok $di->floxed_exons, 'ARRAY', 'floxed exons is an arrayref';

        is scalar @{ $di->floxed_exons }, 6, 'correct number of floxed exons';

        my @expected_exons = qw(ENSMUSE00000143835
            ENSMUSE00000493183
            ENSMUSE00000504553
            ENSMUSE00000572373
            ENSMUSE00000572372
            ENSMUSE00000507603);

        my @got_exons = map { $_->stable_id } @{ $di->floxed_exons };

        ok is_deeply( \@expected_exons, \@got_exons ), 'floxed exons are correct';
    }

    note( 'Test modules when it encounters a nonsense design' );

    {
        ok my $design = model->c_retrieve_design( { id => 10000 } ), 'can grab design 10000';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';

        is $di->target_region_start,136993159, 'correct target region start';
        is $di->target_region_end,136993258, 'correct target region start';
        is $di->chr_strand, -1, 'correct strand';
        is $di->chr_name, 9, 'correct chromosome';
        ok my $target_region_slice = $di->target_region_slice, 'can grab target region slice';
        isa_ok $target_region_slice, 'Bio::EnsEMBL::Slice';

        ok !$di->loxp_start, 'no loxp_start value';
        ok !$di->cassette_start, 'no cassette_start value';
        ok !$di->homology_arm_start, 'no homology_arm_start value';
        is $di->target_transcript->stable_id, 'ENST00000371620', 'correct target transcript';
        ok my $floxed_exons = $di->floxed_exons, 'can call floxed exons';
    }

    note( 'Test target region calculation for a miseq design' );
    {
        ok my $design = model->c_retrieve_design( { id => 1016404 } ),
            'can grab design 1016404';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';

        is $di->target_region_start, 112791780, 'correct target region start';
        is $di->target_region_end, 112791981, 'correct target region end';
    }

    note( 'Test target region calculation for a miseq-nhej design' );
    {
        ok my $design = model->c_retrieve_design( { id => 1016430 } ),
            'can grab design 1016430';
        ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ),
            'can grab new design info object';

        is $di->target_region_start, 60742732, 'correct target region start';
        is $di->target_region_end, 60742936, 'correct target region end';
     }

}

## use critic

1;

__END__
