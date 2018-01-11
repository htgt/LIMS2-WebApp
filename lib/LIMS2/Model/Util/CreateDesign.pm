package LIMS2::Model::Util::CreateDesign;

use strict;
use warnings FATAL => 'all';

use Moose;

use namespace::autoclean;
use Path::Class;
use Sub::Exporter -setup => {
    exports => [
        qw(
              convert_gibson_to_fusion
              create_miseq_design
          )
    ],
};

use LIMS2::Model::Util::DesignTargets qw( prebuild_oligos target_overlaps_exon );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use LIMS2::Exception;
use LIMS2::Exception::Validation;
use WebAppCommon::Util::EnsEMBL;
use Const::Fast;
use TryCatch;
use Hash::MoreUtils qw( slice_def );
use WebAppCommon::Design::FusionConversion qw( modify_fusion_oligos );
use Bio::Perl qw( revcom );
use LIMS2::Model::Util::OligoSelection qw(
        pick_crispr_primers
        pick_single_crispr_primers
        pick_miseq_internal_crispr_primers
        pick_miseq_crispr_PCR_primers
        oligo_for_single_crispr
        pick_crispr_PCR_primers
);
use LIMS2::Model::Util::Crisprs qw( gene_ids_for_crispr ); 
use List::MoreUtils qw( uniq );
use POSIX qw(strftime);
use JSON qw( encode_json );

const my $DEFAULT_DESIGNS_DIR =>  $ENV{ DEFAULT_DESIGNS_DIR } //
                                    '/lustre/scratch117/sciops/team87/lims2_designs';

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
                    design_type_id  => 'fusion-deletion',
                    design_type_id  => 'conditional-inversion',
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

=head2 create_exon_target_design

Wrapper for all the seperate subroutines we need to run to
initiate the creation of a gibson design with a exon target.

=cut
sub create_exon_target_design {
    my ( $self ) = @_;
    my $params         = $self->c_parse_and_validate_exon_target_design_params();
    my $design_attempt = $self->c_initiate_design_attempt( $params );
    $self->calculate_design_targets( $params );
    my $cmd            = $self->c_generate_design_cmd( $params );
    my $job_id         = $self->c_run_design_create_cmd( $cmd, $params );

    return ( $design_attempt, $job_id );
}

=head2 create_custom_target_design

Wrapper for all the seperate subroutines we need to run to
initiate the creation of a gibson design with a custom target.

=cut
sub create_custom_target_design {
    my ( $self ) = @_;

    my $params         = $self->c_parse_and_validate_custom_target_design_params();
    my $design_attempt = $self->c_initiate_design_attempt( $params );
    $self->calculate_design_targets( $params );
    my $cmd            = $self->c_generate_design_cmd( $params );
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

sub convert_gibson_to_fusion {
    my ($self, $c, $id) = @_;
    my $oligo_rs = $c->model('Golgi')->schema->resultset('DesignOligo')->search({ design_id => $id });
    my @oligos;
    my $oligo_rename = {
        '5F'   => 'f5F',
        '3F'    => 'D3',
        '3R'    => 'f3R',
        '5R'   => 'U5',
    };

    while (my $singular_oligo = $oligo_rs->next) {
        my $singular = $singular_oligo->{_column_data};
        my $existing_loci = $singular_oligo->current_locus;
        my $loci_rs = $c->model('Golgi')->schema->resultset('DesignOligoLocus')->search({
            design_oligo_id => $singular->{id},
            assembly_id => $existing_loci->assembly_id
        })->next->{_column_data};
        my $chromosome = $c->model('Golgi')->schema->resultset('Chromosome')->find({ id => $loci_rs->{chr_id}})->{_column_data};
        $self->{species} = $chromosome->{species_id};
        $self->{chr_strand} = $loci_rs->{chr_strand};
        $self->{chr_name} = $chromosome->{name};
        my $loci = {
            'chr_end'       => $loci_rs->{chr_end},
            'chr_start'     => $loci_rs->{chr_start},
            'chr_strand'    => $self->{chr_strand},
            'chr_name'      => $self->{chr_name},
            'assembly'      => $existing_loci->assembly_id,
        };
        my @loci = $loci;
        my $fusion_oligo = $oligo_rename->{$singular->{design_oligo_type_id}};
        if ($fusion_oligo) {
            my $oligo = {
                'type'          => $fusion_oligo,
                'seq'           => $singular->{seq},
                'loci'          => \@loci,
            };
            push @oligos, $oligo;
        }
    }

    $self->_build_ensembl_util();
    my $oligos = \@oligos;
    my @modified_oligos = modify_fusion_oligos($self, $oligos, 1);
    my $gene = $c->model('Golgi')->schema->resultset('GeneDesign')->find({ design_id => $id })->{_column_data};
    my @genes;
    push (@genes, $gene);

    my $attempt = {
        'species'       => $self->{species},
        'created_by'    => $c->user->name,
        'oligos'        => \@oligos,
        'type'          => 'fusion-deletion',
        'gene_ids'      => \@genes,
        'parent_id'     => $id,
    };
    my $design = $c->model( 'Golgi' )->c_create_design( $attempt );
    if ($design) {
        $c->stash->{success_msg} = "Successfully created fusion-deletion design " . $design->id . " from design " . $id;
        $c->response->redirect( $c->uri_for('/user/view_design' , {'design_id'=>$design->id}) );
    }
    else {
        $c->stash->{error_msg} = "Error occured during conversion " . $_;
    }
    return;
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


sub create_miseq_design {
    my ($c, $design, @crisprs) = @_;
$DB::single=1;
    my $search_range = {
        search    => {
            internal    => 170,
            external    => 350,
        },
        dead    => {
            internal    => 50,
            external    => 170,
        },
    };
    my @results;
    foreach my $crispr_id (@crisprs) {
        my $params = {
            crispr_id => $crispr_id,
            species => 'Human',
            repeat_mask => [''],
            offset => 20,
            increment => 15,
            well_id => 'Miseq_Crispr_' . $crispr_id,
        };

        $ENV{'LIMS2_SEQ_SEARCH_FIELD'} = $search_range->{search}->{internal};
        $ENV{'LIMS2_SEQ_DEAD_FIELD'} = $search_range->{dead}->{internal};

        my ($internal_crispr, $internal_crispr_primers) = pick_miseq_internal_crispr_primers($c->model('Golgi'), $params);

        $ENV{'LIMS2_PCR_SEARCH_FIELD'} = $search_range->{search}->{external};
        $ENV{'LIMS2_PCR_DEAD_FIELD'} = $search_range->{dead}->{external};
        $params->{increment} = 50;

        my $crispr_seq = {
            chr_region_start    => $internal_crispr->{left_crispr}->{chr_start},
            left_crispr         => { chr_name   => $internal_crispr->{left_crispr}->{chr_name} },
        };
        my $en_strand = {
            1   => 'plus',
            -1  => 'minus',
        };
        $DB::single=1;
        if ($internal_crispr_primers->{error_flag} eq 'fail' ) {
            print "Primer generation failed: Internal primers - " . $internal_crispr_primers->{error_flag} . "; Crispr:" . $crispr_id . "\n";
            exit;
        }
        $params->{crispr_primers} = { 
            crispr_primers  => $internal_crispr_primers,
            crispr_seq      => $crispr_seq,
            strand          => $en_strand->{$internal_crispr->{left_crispr}->{chr_strand}},
        };

        my ($pcr_crispr, $pcr_crispr_primers) = pick_miseq_crispr_PCR_primers($c->model('Golgi'), $params);

        $DB::single=1;
        if ($pcr_crispr_primers->{error_flag} eq 'fail') {
            print "Primer generation failed: PCR results - " . $pcr_crispr_primers->{error_flag} . "; Crispr " . $crispr_id . "\n";
            exit;
        } elsif ($pcr_crispr_primers->{genomic_error_flag} eq 'fail') {
            print "PCR genomic check failed; PCR results - " . $pcr_crispr_primers->{genomic_error_flag} . "; Crispr " . $crispr_id . "\n";
            exit;
        }

        my $slice_adaptor = $c->model('Golgi')->ensembl_slice_adaptor('Human');
        my $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $internal_crispr->{'left_crispr'}->{'chr_name'},
            $internal_crispr->{'left_crispr'}->{'chr_start'} - 1000,
            $internal_crispr->{'left_crispr'}->{'chr_end'} + 1000,
            1,
        );
        my $crispr_loc = index ($slice_region->seq, $internal_crispr->{left_crispr}->{seq});
        my ($inf, $inr) = find_appropriate_primers($internal_crispr_primers, 260, 297, $slice_region->seq, $crispr_loc);
        my ($exf, $exr) = find_appropriate_primers($pcr_crispr_primers, 750, 3000, $slice_region->seq);
$DB::single=1;
        my $result = {
            crispr  => $internal_crispr->{left_crispr}->{id},
            genomic => $pcr_crispr_primers->{pair_count},
            oligos  => {
                inf => $inf,
                inr => $inr,
                exf => $exf,
                exr => $exr,
            },
        };
        push @results, $result;
        package_parameter($c, $design, $result, $search_range->{dead});
    }
    return @results;
};

sub find_appropriate_primers {
    my ($crispr_primers, $target, $max, $region, $crispr) = @_;

    #print Dumper $crispr_primers;
    my @primers = keys %{$crispr_primers->{left}};
    my $closest->{record} = 5000;
    my @test;
    foreach my $prime (@primers) {
        my $int = (split /_/, $prime)[1];
        my $left_location_details = $crispr_primers->{left}->{'left_' . $int}->{location};
        my $right_location_details = $crispr_primers->{right}->{'right_' . $int}->{location};
        my $range = $right_location_details->{_start} - $left_location_details->{_end};
        my $start_coord = index ($region, $crispr_primers->{left}->{'left_' . $int}->{seq});
        my $end_coord = index ($region, revcom($crispr_primers->{right}->{'right_' . $int}->{seq})->seq);
        my $primer_diff = abs (($end_coord - 1022) - (1000 - $start_coord));

        my $primer_range = {
            name    => '_' . $int,
            start   => $left_location_details->{_end},
            end     => $right_location_details->{_start},
            lseq    => $crispr_primers->{left}->{'left_' . $int}->{seq},
            rseq    => $crispr_primers->{right}->{'right_' . $int}->{seq},
            range   => $range,
            diff    => $primer_diff,
        };

        push @test, $primer_range;
        if ($range < $max) {
            my $amplicon_score = ($target - $range) + $primer_diff;
            if ($amplicon_score < $closest->{record}) {
                $closest = {
                    record  => $amplicon_score,
                    primer  => $int,
                };
            }
        }
    }
use Data::Dumper;
    #print Dumper @test;
    print Dumper $closest;
    return $crispr_primers->{left}->{'left_' . $closest->{primer}}, $crispr_primers->{right}->{'right_' . $closest->{primer}};
}

sub package_parameter {
    my ($c, $design_params, $result_data, $offset) = @_;

    my $crispr_rs = $c->model('Golgi')->schema->resultset('Crispr')->find({ id => $result_data->{crispr} });
    my $crispr_details = $crispr_rs->as_hash;
    my $date = strftime "%d-%m-%Y", localtime;
    my $version = $c->model('Golgi')->software_version . '_' . $date;
    use YAML::XS qw( LoadFile );
$DB::single=1;
    my $miseq_pcr_conf = LoadFile($ENV{ 'LIMS2_PRIMER3_PCR_CRISPR_PRIMER_CONFIG' });
    my $miseq_internal_conf = LoadFile($ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' });

    my $design_spec;
    my $design_parameters = {
        design_method       => $design_params->{design_type},
        'command-name'      => $design_params->{design_type} . '-design-location',
        assembly            => $crispr_details->{locus}->{assembly},
        created_by          => $c->{session}->{user},

        three_prime_exon    => 'null',
        five_prime_exon     => 'null',
        oligo_three_prime_align => '0',
        exon_check_flank_length =>  '0',
        primer_lowercase_masking    => $miseq_pcr_conf->{primer_lowercase_masking},
        num_genomic_hits            => $result_data->{genomic},

        region_length_3F    => '20',
        region_length_3R    => '20',
        region_length_5F    => '20',
        region_length_5R    => '20',

        region_offset_3F    => $offset->{internal},
        region_offset_3R    => $offset->{internal},
        region_offset_5F    => $offset->{external},
        region_offset_5R    => $offset->{external},

        primer_min_size     => $miseq_pcr_conf->{primer_min_size},
        primer_opt_size     => $miseq_pcr_conf->{primer_opt_size},
        primer_max_size     => $miseq_pcr_conf->{primer_max_size},

        primer_min_gc       => $miseq_pcr_conf->{primer_min_gc},
        primer_opt_gc_content   => $miseq_pcr_conf->{primer_opt_gc_percent},
        primer_max_gc       => $miseq_pcr_conf->{primer_max_gc},
           
        primer_min_tm       => $miseq_pcr_conf->{primer_min_tm},
        primer_opt_tm       => $miseq_pcr_conf->{primer_opt_tm},
        primer_max_tm       => $miseq_pcr_conf->{primer_max_tm},

        repeat_mask_class   => [],
            
        software_version    => $version,
    };

    $design_spec->{design_parameters} = $design_parameters;
    $design_spec->{created_by} = $c->user->name;
    $design_spec->{species} = $c->session->{selected_species};
    $design_spec->{type} = $design_params->{design_type};

    my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };


    my @gene_ids;
    my @hgnc_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr_rs, $c->model('Golgi') ) };

    foreach my $hgnc_id (@hgnc_ids) {
        my $gene_spec = {
            gene_id => $hgnc_id,
            gene_type_id => 'HGNC',
        };
        push @gene_ids, $gene_spec;
    }

    $design_spec->{gene_ids} = @gene_ids;
    my $oligos = format_oligos($result_data->{oligos});

    my $design_json = encode_json ({
        design_parameters   => $design_parameters,
        created_by          => $c->user->name,
        species             => $c->session->{selected_species},
        type                => $design_params->{design_type},
        gene_ids            => @gene_ids,
        oligos              => $oligos,
    });
    
    my $design = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->c_create_design( $design_json );
        }
    );

}

sub format_oligos {
    my $primers = shift;

    my @oligos;
    my $rev_oligo = {
        1   => {
            inf => 1,
            inr => -1,
            exf => 1,
            exr => -1,
        },
        -1  => {
            inf => -1,
            inr => 1,
            exf => -1,
            exr => 1,
        },
    };
$DB::single=1;
    foreach my $primer (keys %$primers) {
        my $primer_data = $primers->{$primer};
        my $seq = $primer_data->{seq};
        if ($rev_oligo->{ $primer_data->{location}->{_strand} }->{$primer} == -1) {
            $seq = revcom($seq)->seq;
        }
        my $oligo = {
            loci    => [ $primer_data->{loci} ],
            seq     => uc $seq,
            type    => uc $primer,
        };
        push(@oligos, $oligo);
    }

    return \@oligos;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
