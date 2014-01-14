package LIMS2::Model::Util::CreateDesign;

use warnings FATAL => 'all';

use Moose;
use LIMS2::Model::Util::DesignTargets qw( prebuild_oligos );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use WebAppCommon::Util::EnsEMBL;
use Path::Class;
use Const::Fast;
use TryCatch;
use namespace::autoclean;

const my $DEFAULT_DESIGNS_DIR =>  $ENV{ DEFAULT_DESIGNS_DIR } //
                                    '/lustre/scratch109/sanger/team87/lims2_designs';

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
    handles  => {
        check_params          => 'check_params',
        create_design_attempt => 'create_design_attempt',
    }
);

has catalyst => (
    is       => 'ro',
    isa      => 'Catalyst',
    required => 1,
);

has species => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_species {
    my $self = shift;

    return $self->catalyst->session->{selected_species};
}

has ensembl_util => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::EnsEMBL',
    lazy_build => 1,
);

sub _build_ensembl_util {
    my $self = shift;

    return WebAppCommon::Util::EnsEMBL->new( species => $self->species );
}

has user => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_user {
    my $self = shift;

    return $self->catalyst->user->name;
}

has assembly_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_assembly_id {
    my $self = shift;

    return $self->model->schema->resultset('SpeciesDefaultAssembly')
        ->find( { species_id => $self->species } )->assembly_id;
}

has build_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_build_id {
    my $self = shift;

    return $DEFAULT_SPECIES_BUILD{ lc($self->species) };
}

has base_design_dir => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    lazy_build => 1,
);

sub _build_base_design_dir {
    return dir( $DEFAULT_DESIGNS_DIR );
}

with qw(
MooseX::Log::Log4perl
WebAppCommon::Design::CreateInterface
);

=head2 exons_for_gene

Given a gene name find all its exons that could be targeted for a design.
Optionally get all exons or just exons from canonical transcript.

=cut
sub exons_for_gene {
    my ( $self, $gene_name, $exon_types ) = @_;

    my $gene = $self->ensembl_util->get_ensembl_gene( $gene_name );
    return unless $gene;

    my $gene_data = $self->c_build_gene_data( $gene );

    my $exon_data = $self->c_build_gene_exon_data( $gene, $gene_data->{gene_id}, $exon_types );
    $self->designs_for_exons( $exon_data, $gene_data->{gene_id} );
    $self->design_targets_for_exons( $exon_data, $gene->stable_id );

    return ( $gene_data, $exon_data );
}

=head2 designs_for_exons

Grab any existing designs for the exons.

=cut
sub designs_for_exons {
    my ( $self, $exons, $gene_id ) = @_;

    my @designs = $self->model->schema->resultset('Design')->search(
        {
            'genes.gene_id' => $gene_id,
            'me.species_id' => $self->species,
            design_type_id  => 'gibson',
        },
        {
            join     => 'genes',
            prefetch =>  { 'oligos' => { 'loci' => 'chr' } },
        },
    );

    my $assembly = $self->model->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $self->species } )->assembly_id;

    for my $exon ( @{ $exons } ) {
        my @matching_designs;

        for my $design ( @designs ) {
            my $oligo_data = prebuild_oligos( $design, $assembly );
            # if no oligo data then design does not have oligos on assembly
            next unless $oligo_data;
            my $di = LIMS2::Model::Util::DesignInfo->new(
                design => $design,
                oligos => $oligo_data,
            );
            if ( $exon->{start} > $di->target_region_start
                && $exon->{end} < $di->target_region_end
                && $exon->{chr} eq $di->chr_name
            ) {
                push @matching_designs, $design;
            }
        }
        $exon->{designs} = [ map { $_->id } @matching_designs ]
            if @matching_designs;
    }

    return;
}

=head2 design_targets_for_exons

Note if any of the exons are already design targets.
This indicates they have been picked as good targets either by
a automatic target finding script or a human.

=cut
sub design_targets_for_exons {
    my ( $self, $exons, $ensembl_gene_id ) = @_;

    my $dt_rs = $self->model->schema->resultset('DesignTarget')->search(
        { ensembl_gene_id => $ensembl_gene_id } );

    for my $exon ( @{ $exons } ) {
        if ( my $dt = $dt_rs->find( { ensembl_exon_id => $exon->{id} } ) ) {
            $exon->{dt} = 1;
        }
        else {
            $exon->{dt} = 0;
        }
    }

    return;
}

=head2 create_gibson_design

Wrapper for all the seperate subroutines we need to run to
initiate the creation of a gibson design

=cut
sub create_gibson_design {
    my ( $self ) = @_;

    my $params         = $self->c_parse_and_validate_gibson_params();
    my $design_attempt = $self->c_initiate_design_attempt( $params );
    my $design_target  = $self->find_or_create_design_target( $params );
    my $cmd            = $self->c_generate_gibson_design_cmd( $params );
    my $job_id         = $self->c_run_design_create_cmd( $cmd, $params );

    return $design_attempt;
}

=head2 find_or_create_design_target

If a design target does not already exists for the targeted exon
create one. This will make the exon along with its designs / crisprs
show up in the reports based on the design targets table.

=cut
sub find_or_create_design_target {
    my ( $self, $params ) = @_;

    my $existing_design_target = $self->model->schema->resultset('DesignTarget')->find(
        {
            species_id      => $params->{species},
            ensembl_exon_id => $params->{exon_id},
            build_id        => $params->{build_id},
        }
    );

    if ( $existing_design_target ) {
        $self->log->debug( 'Design target ' . $existing_design_target->id
                . ' already exists for exon: ' . $params->{exon_id} );
        return $existing_design_target;
    }

    my $gene = $self->ensembl_util->get_ensembl_gene( $params->{ensembl_gene_id} );
    die( "Unable to find ensembl gene: " . $params->{ensembl_gene_id} )
        unless $gene;
    my $canonical_transcript = $gene->canonical_transcript;

    my $exon;
    try {
        $exon = $self->ensembl_util->exon_adaptor( $self->species )
            ->fetch_by_stable_id( $params->{exon_id} );
    }
    die( "Unable to find ensembl exon for: " . $params->{exon_id} )
        unless $exon;

    my %design_target_params = (
        species              => $params->{species},
        gene_id              => $params->{gene_id},
        marker_symbol        => $gene->external_name,
        ensembl_gene_id      => $gene->stable_id,
        ensembl_exon_id      => $params->{exon_id},
        exon_size            => $exon->length,
        canonical_transcript => $canonical_transcript->stable_id,
        assembly             => $params->{assembly_id},
        build                => $params->{build_id},
        chr_name             => $exon->seq_region_name,
        chr_start            => $exon->seq_region_start,
        chr_end              => $exon->seq_region_end,
        chr_strand           => $exon->seq_region_strand,
        automatically_picked => 0,
        comment              => 'picked via gibson design creation interface, by user: ' . $params->{user},

    );
    my $exon_rank = try{ $self->ensembl_util->get_exon_rank( $canonical_transcript, $exon->stable_id ) };
    $design_target_params{exon_rank} = $exon_rank if $exon_rank;
    my $design_target = $self->model->create_design_target( \%design_target_params );

    return $design_target;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
