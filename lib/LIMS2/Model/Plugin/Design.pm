package LIMS2::Model::Plugin::Design;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

has _design_comment_category_ids => (
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    lazy_build  => 1,
    handles     => {
        design_comment_category_id_for => 'get'
    }
);

sub _build__design_comment_category_ids {
    my $self = shift;

    my %category_id_for = map { $_->name => $_->id }
        $self->schema->resultset( 'DesignCommentCategory' )->all;

    return \%category_id_for;
}

sub pspec_create_design {
    return {
        id                      => { validate => 'integer' },
        type                    => { validate => 'existing_design_type', rename => 'design_type_id' },
        created_at              => { validate => 'date_time', post_filter => 'parse_date_time' },
        created_by              => { validate => 'existing_user', post_filter => 'user_id_for' },
        phase                   => { validate => 'phase' },
        validated_by_annotation => { validate => 'validated_by_annotation', default => 'not done' },
        name                    => { validate => 'alphanumeric_string' },
        target_transcript       => { optional => 1, validate => 'ensembl_transcript_id' },
        oligos                  => { optional => 1 },
        comments                => { optional => 1 },
        genotyping_primers      => { optional => 1 },
        gene_ids                => { validate => 'mgi_accession_id', optional => 1 }
    };
}

sub pspec_create_design_comment {
    return {
        category       =>  { validate    => 'existing_design_comment_category',
                             post_filter => 'design_comment_category_id_for',
                             rename      => 'design_comment_category_id' },
        comment_text   => { optional => 1 },
        created_at     => { validate => 'date_time', post_filter => 'parse_date_time' },
        created_by     => { validate => 'existing_user', post_filter => 'user_id_for' },
        is_public      => { validate => 'boolean', default => 0 }
    }
}

sub pspec_create_design_oligo {
    return {
        type => { validate => 'existing_design_oligo_type', rename => 'design_oligo_type_id' },
        seq  => { validate => 'dna_seq' },
        loci => { optional => 1 }
    }
}

sub pspec_create_design_oligo_locus {
    return {
        assembly   => { validate => 'existing_assembly', rename => 'assembly_id' },
        chr_name   => { validate => 'existing_chromosome', rename => 'chr_id' },
        chr_start  => { validate => 'integer' },
        chr_end    => { validate => 'integer' },
        chr_strand => { validate => 'strand' },
    }
}

sub pspec_create_genotyping_primer {
    return {
        type => { validate => 'existing_genotyping_primer_type', rename => 'genotyping_primer_type_id' },
        seq  => { validate => 'dna_seq' }
    }
}

sub create_design {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_design );

    $self->log->debug( "Create design $validated_params->{id}" );
    my $design = $self->schema->resultset( 'Design' )->create(
        {
            slice_def( $validated_params,
                       qw( id name created_by created_at design_type_id phase
                           validated_by_annotation target_transcript ) )
        }
    );

    for my $g ( @{ $validated_params->{gene_ids} } ) {
        $self->trace( "Create gene_design $g" );
        $design->create_related( genes => { gene_id => $g, created_by => $self->user_id_for( 'unknown' ) } );
    }
    
    for my $c ( @{ $validated_params->{comments} || [] } ) {
        $self->trace( "Create design comment", $c );
        my $validated = $self->check_params( $c, $self->pspec_create_design_comment );
        $design->create_related( comments => $validated );
    }

    for my $o ( @{ $validated_params->{oligos} || [] } ) {
        $self->trace( "Create design oligo", $o );
        my $validated = $self->check_params( $o, $self->pspec_create_design_oligo );
        my $loci = delete $validated->{loci};
        my $oligo = $design->create_related( oligos => $validated );
        for my $l ( @{ $loci || [] } ) {
            $self->trace( "Create oligo locus", $l );
            my $validated = $self->check_params( $l, $self->pspec_create_design_oligo_locus );
            $oligo->create_related( loci => $validated );
        }
    }

    for my $p ( @{ $validated_params->{genotyping_primers} || [] } ) {
        $self->trace( "Create genotyping primer", $p );        
        my $validated = $self->check_params( $p, $self->pspec_create_genotyping_primer );
        $design->create_related( genotyping_primers => $validated );
    }

    return $design;
}

sub pspec_delete_design {
    return {
        id      => { validate => 'integer' },
        cascade => { validate => 'boolean', optional => 1 }
    }
}

sub delete_design {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_design );

    my %search = slice( $validated_params, 'id' );
    my $design = $self->schema->resultset( 'Design' )->find( \%search )
        or $self->throw(
            NotFound => {
                entity_class  => 'Design',
                search_params => \%search
            }
        );

    # # Check that design is not allocated to a process and, if it is, refuse to delete
    # # XXX When we introduce project/design request to model, also need to check that design
    # # is not attached to a project/design request.

    # if ( $design->process_cre_bac_recoms_rs->count > 0
    #          or $design->process_create_dis_rs->count > 0 ) {
    #     $self->throw( InvalidState => 'Design ' . $design->design_id . ' is used in one or more processes' );
    # }

    if ( $validated_params->{cascade} ) {
        $design->comments_rs->delete;
        $design->oligos_rs->delete;
        $design->genotyping_primers_rs->delete;
    }

    $design->delete;

    return 1;
}

sub pspec_retrieve_design {
    return {
        id => { validate => 'integer' }
    }
}

sub retrieve_design {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_design );

    my $design = $self->retrieve( Design => $validated_params );

    return $design;
}

sub pspec_list_designs_for_gene {
    return {
        gene => { validate => 'non_empty_string' },
        type => { validate => 'existing_design_type', optional => 1 }
    }
}

sub list_designs_for_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_designs_for_gene );

    my $genes = $self->search_genes( { slice $validated_params, 'gene' } );

    my $design_rs = $self->schema->resultset('Design')->search(
        {
            'genes.gene_id' => { '-in' => [ map { $_->{mgi_accession_id} } @{$genes} ] }
        },
        {
            join => 'genes'
        }
    );

    if ( $validated_params->{type} ) {
        $design_rs->search( { 'me.type' => $validated_params->{type} } );
    }

    return [ $design_rs->all ];
}

sub pspec_list_candidate_designs_for_gene {
    return {
        gene => { validate => 'non_empty_string' },
        type => { validate => 'existing_design_type', optional => 1 }
    }
}

sub list_candidate_designs_for_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_candidate_designs_for_gene );

    my $genes = $self->search_genes( $validated_params );

    # XXX TODO: retrieve gene from EnsEMBL, search for overlapping designs
}

1;

__END__
