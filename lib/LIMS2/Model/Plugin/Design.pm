package LIMS2::Model::Plugin::Design;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Design::VERSION = '0.003';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use List::Util qw( max min );
use List::MoreUtils qw( uniq );
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

sub list_design_types {
    my $self = shift;

    my $rs = $self->schema->resultset( 'DesignType' )->search( {}, { order_by => { -asc => 'id' } } );

    return [ map { $_->id } $rs->all ];
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
        my $validated_oligo = $self->check_params( $o, $self->pspec_create_design_oligo );
        my $loci = delete $validated_oligo->{loci};
        my $oligo = $design->create_related( oligos => $validated_oligo );
        for my $l ( @{ $loci || [] } ) {
            $self->trace( "Create oligo locus", $l );
            my $validated_locus = $self->check_params( $l, $self->pspec_create_design_oligo_locus );
            $oligo->create_related( loci => $validated_locus );
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

sub pspec_list_assigned_designs_for_gene {
    return {
        gene_id => { validate => 'mgi_accession_id' },
        type    => { validate => 'existing_design_type', optional => 1 }
    }
}

sub list_assigned_designs_for_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_assigned_designs_for_gene );

    my %search = (
        'genes.gene_id' => $validated_params->{gene_id}
    );

    if ( defined $validated_params->{type} ) {
        $search{'me.design_type_id'} = $validated_params->{type};
    }

    my $design_rs = $self->schema->resultset('Design')->search( \%search, { join => 'genes' } );

    return [ $design_rs->all ];
}

sub pspec_list_candidate_designs_for_gene {
    return {
        gene_id => { validate => 'mgi_accession_id' },
        type    => { validate => 'existing_design_type', optional => 1 }
    }
}

sub list_candidate_designs_for_gene {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_candidate_designs_for_gene );

    my ( $chr, $start, $end, $strand ) = $self->_get_gene_chr_start_end_strand( $validated_params->{gene_id} );

    my %search = (
        'ncbim37_locus.chr_name'   => $chr,
        'ncbim37_locus.chr_strand' => $strand,
    );

    if ( $strand == 1 ) {
        $search{'ncbim37_locus.u5_end'}   = { '<', $end };
        $search{'ncbim37_locus.d3_start'} = { '>', $start };
    }
    else {
        $search{'ncbim37_locus.d3_end'}   = { '<', $end };
        $search{'ncbim37_locus.u5_start'} = { '>', $start };
    }

    if ( defined $validated_params->{type} ) {
        $search{'me.design_type_id'} = $validated_params->{type};
    }

    my $design_rs = $self->schema->resultset('Design')->search( \%search, { join => 'ncbim37_locus' } );

    return [ $design_rs->all ];
}

sub _get_gene_chr_start_end_strand {
    my ( $self, $mgi_accession_id ) = @_;

    my @ensembl_genes = @{ $self->ensembl_gene_adaptor->fetch_all_by_external_name( $mgi_accession_id ) };

    if ( @ensembl_genes == 0 ) {
        $self->throw(
            NotFound => {
                message       => 'Found no matching EnsEMBL genes',
                entity        => 'EnsEMBL Gene',
                search_params => { external_id => $mgi_accession_id }
            }
        );
    }

    my @gene_chr = uniq( map { $_->seq_region_name } @ensembl_genes );
    if ( @gene_chr != 1 ) {
        $self->throw(
            InvalidState => sprintf( 'EnsEMBL genes (%s) have different chromosomes',
                                     join( q{, }, map { $_->stable_id } @ensembl_genes ) )
        );
    }

    my @gene_strand = uniq( map { $_->seq_region_strand } @ensembl_genes );
    if ( @gene_strand != 1 ) {
        $self->throw(
            InvalidState => sprintf( 'EnsEMBL genes (%s) have different strands',
                                     join( q{, }, map { $_->stable_id } @ensembl_genes ) )
        );
    }

    my $gene_start  = min( map { $_->seq_region_start } @ensembl_genes );
    my $gene_end    = max( map { $_->seq_region_end   } @ensembl_genes );

    return ( $gene_chr[0], $gene_start, $gene_end, $gene_strand[0] );
}

1;

__END__
