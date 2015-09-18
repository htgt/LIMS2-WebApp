package LIMS2::Model::Util::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateDesign::VERSION = '0.338';
}
## use critic


use warnings FATAL => 'all';

use Moose;
use LIMS2::Model::Util::DesignTargets qw( prebuild_oligos target_overlaps_exon );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use LIMS2::Exception;
use LIMS2::Exception::Validation;
use WebAppCommon::Util::EnsEMBL;
use Path::Class;
use Const::Fast;
use TryCatch;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;

const my $DEFAULT_DESIGNS_DIR =>  $ENV{ DEFAULT_DESIGNS_DIR } //
                                    '/lustre/scratch109/sanger/team87/lims2_designs';

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
    handles  => {
        check_params          => 'check_params',
        create_design_attempt => 'c_create_design_attempt',
        c_create_design_attempt => 'c_create_design_attempt',
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

    my $gene;
    try {
        $gene = $self->ensembl_util->get_ensembl_gene( $gene_name );
        die "Unable to find gene $gene_name in Ensemble database" unless $gene;
    }
    catch ( $err ){
        LIMS2::Exception::Validation->throw(
            message => $err,
        );
    }

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
            -and => [
                'genes.gene_id' => $gene_id,
                'me.species_id' => $self->species,
                -or => [
                    design_type_id  => 'gibson',
                    design_type_id  => 'gibson-deletion',
                ],
            ],
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

        #TODO refactor, we are working out same design coordinates multiple times sp12 Mon 24 Feb 2014 13:20:23 GMT
        for my $design ( @designs ) {
            my $oligo_data = prebuild_oligos( $design, $assembly );
            # if no oligo data then design does not have oligos on assembly
            next unless $oligo_data;
            my $di = LIMS2::Model::Util::DesignInfo->new(
                design => $design,
                oligos => $oligo_data,
            );
            next unless $exon->{chr} eq $di->chr_name;

            if (target_overlaps_exon(
                    $di->target_region_start, $di->target_region_end,
                    $exon->{start},           $exon->{end} )
               )
            {
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
        if ( my $dt = $dt_rs->find( { ensembl_exon_id => $exon->{id}, assembly_id => $self->assembly_id } ) ) {
            $exon->{dt} = 1;
        }
        else {
            $exon->{dt} = 0;
        }
    }

    return;
}

=head2 create_exon_target_gibson_design

Wrapper for all the seperate subroutines we need to run to
initiate the creation of a gibson design with a exon target.

=cut
sub create_exon_target_gibson_design {
    my ( $self ) = @_;

    my $params         = $self->c_parse_and_validate_exon_target_gibson_params();
    my $design_attempt = $self->c_initiate_design_attempt( $params );
    $self->calculate_design_targets( $params );
    my $cmd            = $self->c_generate_gibson_design_cmd( $params );
    my $job_id         = $self->c_run_design_create_cmd( $cmd, $params );

    return ( $design_attempt, $job_id );
}

=head2 create_custom_target_gibson_design

Wrapper for all the seperate subroutines we need to run to
initiate the creation of a gibson design with a custom target.

=cut
sub create_custom_target_gibson_design {
    my ( $self ) = @_;

    my $params         = $self->c_parse_and_validate_custom_target_gibson_params();
    my $design_attempt = $self->c_initiate_design_attempt( $params );
    $self->calculate_design_targets( $params );
    my $cmd            = $self->c_generate_gibson_design_cmd( $params );
    my $job_id         = $self->c_run_design_create_cmd( $cmd, $params );

    return ( $design_attempt, $job_id );
}

=head2 calculate_design_targets

Try to work out the design targets for a gibson design
and create any appropriate design targets.

=cut
sub calculate_design_targets {
    my ( $self, $params ) = @_;

    # get gene
    my $gene_name = $params->{ensembl_gene_id} || $params->{gene_id};
    my $gene = $self->ensembl_util->get_ensembl_gene( $gene_name );
    return unless $gene;
    my $exon_adaptor = $self->ensembl_util->exon_adaptor;

    # if no 3 prime, only 5 prime exon. target it
    if ( $params->{five_prime_exon} && !$params->{three_prime_exon} ) {
        my $five_prime_exon = $exon_adaptor->fetch_by_stable_id( $params->{five_prime_exon} );
        $self->find_or_create_design_target( $params, $five_prime_exon, $gene );

        return;
    }

    # get target start and end
    my $target_start;
    my $target_end;
    my $chromosome;
    if ( $params->{target_start} && $params->{target_end} ) {
        $target_start = $params->{target_start};
        $target_end   = $params->{target_end};
        $chromosome   = $params->{chr_name};
    }
    else {
        if ( $params->{five_prime_exon} && $params->{three_prime_exon} ) {
            my $five_prime_exon  = $exon_adaptor->fetch_by_stable_id( $params->{five_prime_exon} );
            my $three_prime_exon = $exon_adaptor->fetch_by_stable_id( $params->{three_prime_exon} );
            if ( $gene->strand == 1 ) {
                $target_start = $five_prime_exon->seq_region_start;
                $target_end   = $three_prime_exon->seq_region_end;
            }
            else {
                $target_start = $three_prime_exon->seq_region_start;
                $target_end   = $five_prime_exon->seq_region_end;
            }
            $chromosome = $five_prime_exon->seq_region_name;
        }
    }

    # grab canonical exons for gene
    my $exons = $gene->canonical_transcript->get_all_Exons;

    # identify all canonical exons which land between target start and target end
    # is a match if the exon is a partial hit as well
    my @target_exons;
    for my $exon ( @{$exons} ) {
        next unless $chromosome eq $exon->seq_region_name;
        if (target_overlaps_exon(
                $target_start, $target_end, $exon->seq_region_start, $exon->seq_region_end )
            )
        {
            push @target_exons, $exon;
        }
    }

    $self->find_or_create_design_target( $params, $_, $gene ) for @target_exons;

    return;
}

=head2 find_or_create_design_target

If a design target does not already exists for the targeted exon
create one. This will make the exon along with its designs / crisprs
show up in the reports based on the design targets table.

=cut
sub find_or_create_design_target {
    my ( $self, $params, $exon, $gene ) = @_;

    my $exon_id = $exon ? $exon->stable_id : $params->{exon_id};

    my $existing_design_target = $self->model->schema->resultset('DesignTarget')->find(
        {
            species_id      => $params->{species},
            ensembl_exon_id => $exon_id,
            build_id        => $params->{build_id},
        }
    );

    if ( $existing_design_target ) {
        $self->log->info( 'Design target ' . $existing_design_target->id
                . ' already exists for exon: ' . $exon_id );
        return $existing_design_target;
    }

    $gene ||= $self->ensembl_util->get_ensembl_gene( $params->{ensembl_gene_id} );
    die( "Unable to find ensembl gene: " . $params->{ensembl_gene_id} )
        unless $gene;
    my $canonical_transcript = $gene->canonical_transcript;

    try {
        $exon ||= $self->ensembl_util->exon_adaptor( $self->species )
            ->fetch_by_stable_id( $exon_id );
    }
    die( "Unable to find ensembl exon for: " . $exon_id )
        unless $exon;

    my %design_target_params = (
        species              => $params->{species},
        gene_id              => $params->{gene_id},
        marker_symbol        => $gene->external_name,
        ensembl_gene_id      => $gene->stable_id,
        ensembl_exon_id      => $exon_id,
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
    my $design_target = $self->model->c_create_design_target( \%design_target_params );

    return $design_target;
}

=head create_point_mutation_design

Provide a wild type sequence (or its coordinates) and oligo sequence containing point mutation
to create a design. Does some validation of wt vs mutant oligo sequence.

=cut

sub _pspec_create_point_mutation_design{
    return {
        oligo_sequence     => { validate => 'dna_seq' },
        chr_name           => { validate => 'existing_chromosome' },
        chr_start          => { validate => 'integer' },
        chr_end            => { validate => 'integer' },
        chr_strand         => { validate => 'strand'  },
    }
}

sub create_point_mutation_design{
    my ($self, $params) = @_;

    my $validated_params = $self->model->check_params( $params, $self->_pspec_create_point_mutation_design, ignore_unknown => 1 );

    my $locus = { slice_def $validated_params, qw(chr_name chr_strand chr_start chr_end) };

    my $assembly = $self->model->get_species_default_assembly($self->species);
    $locus->{assembly} = $assembly;

    # find wild type sequence in ensembl
    my $slice = $self->ensembl_util->slice_adaptor->fetch_by_region(
        'chromosome',
        $locus->{chr_name},
        $locus->{chr_start},
        $locus->{chr_end},
        $locus->{chr_strand}
    );
    my $wild_type_sequence = $slice->seq();
    $self->log->debug("Got wild type sequence $wild_type_sequence");

    my $oligo_sequence = $self->mutant_seq_with_lower_case({
        mutant_seq    => $validated_params->{oligo_sequence},
        wild_type_seq => $wild_type_sequence,
        max_mismatch_percent => 10,
    });

    # delete point mutation design specific params as the remaining params
    # will be passed to the generic design creation method
    delete @{$params}{qw( oligo_sequence chr_name chr_strand chr_start chr_end wild_type_sequence)};

    # add the oligo and loci information to params
    $params->{oligos} = [
        {
            type => 'PM',
            seq  => $oligo_sequence,
            loci => [ $locus ],
        }
    ];

    $params->{species} = $self->species;
    $params->{created_by} = $self->user;

    my $design;
    $self->model->txn_do(
        sub {
            try {
                $design = $self->model->c_create_design($params);
            }
            catch ($err){
                $self->log->error( "Error creating point muation design: $err" );
                $self->model->txn_rollback;

                #re-throw error so it goes to webapp
                die $err;
            };
        }
    );

    return $design;
}

=head2 mutant_seq_with_lower_case

Return mutant seq with lower case characters where it does not match
wild type seq. (comparison is base by base and assumes strings are same
length with no insertions/deletions)

=cut

sub mutant_seq_with_lower_case{
    my ($self, $params) = @_;
    my $mutant = $params->{mutant_seq} or die "No mutant_seq parameter provided";
    my $wt = $params->{wild_type_seq} or die "No wild_type_seq parameter provided";

    my @mutant_chars = map { uc $_ } split "", $mutant;
    my @wt_chars = map { uc $_ } split "", $wt;

    if(scalar @mutant_chars != scalar @wt_chars){
        die "Wild type sequences are different lengths. Cannot compare.";
    }

    my @new_chars;
    my $mismatch_count = 0;
    foreach my $i (0..$#mutant_chars){
        if( $mutant_chars[$i] eq $wt_chars[$i] ){
            push @new_chars, $mutant_chars[$i];
        }
        else{
            $self->log->debug("Sequence mismatch identified at position $i of oligo");
            $mismatch_count++;
            push @new_chars, lc( $mutant_chars[$i] );
        }
    }

    my $new = join "", @new_chars;

    my $max_mismatch_percent = $params->{max_mismatch_percent};
    if(defined $max_mismatch_percent){
        my $percent = ( $mismatch_count / scalar(@mutant_chars) ) * 100;
        $self->log->debug("Mismatch percent: $percent");
        if($percent > $max_mismatch_percent){
            die "More than $max_mismatch_percent % mismatch found between sequences:\n"
                ."Wild type: $wt\n"
                ."Mutant   : $mutant";
        }
    }
    return $new;
}
=head2 throw_validation_error

Override parent throw method to use LIMS2::Exception::Validation.

=cut
around 'throw_validation_error' => sub {
    my $orig = shift;
    my $self = shift;
    my $errors = shift;

    LIMS2::Exception::Validation->throw(
        message => $errors,
    );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
