package LIMS2::Model::Util::AlleleDetermination;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::AlleleDetermination::VERSION = '0.119';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use LIMS2::Exception;
use Parse::BooleanLogic;

# use Smart::Comments;

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

# array of hashrefs of well genotyping results
has well_genotyping_results_array => (
    is  => 'rw',
    isa => 'ArrayRef[HashRef]',
);

# ordered array of well ids
has well_ids => (
    is  => 'rw',
    isa => 'ArrayRef[Int]',
);

# results hash (key = well id, value = allele type)
has well_allele_type_results => (
    is  => 'rw',
    isa => 'HashRef',
);

has current_well => (
    is  => 'rw',
    isa => 'HashRef',
);

has current_well_id => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
);

has current_well_workflow => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has current_well_stage => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has current_well_validation_msg => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has allele_config => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_allele_config',
);

has assay_dispatches => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has validation_dispatches => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has allele_translation => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_allele_translation',
);

sub BUILD {
    my ($self) = @_;
    return;
}

sub _build_allele_config {
    my ($self) = @_;

    my $conf_parser = Config::Scoped->new(
        file     => $ENV{LIMS2_ALLELE_DET_CONFIG},
        warnings => { permissions => 'off' }
    );

    my $allele_config = $conf_parser->parse;

    return $allele_config;
}

sub _build_assay_dispatches {
    my ($self) = @_;

    my $assay_dispatches = {
        'is_loacrit_0'           => sub { $self->is_loacrit_0 },
        'is_loacrit_1'           => sub { $self->is_loacrit_1 },
        'is_loacrit_2'           => sub { $self->is_loacrit_2 },
        'is_loatam_0'            => sub { $self->is_loatam_0 },
        'is_loatam_1'            => sub { $self->is_loatam_1 },
        'is_loatam_2'            => sub { $self->is_loatam_2 },
        'is_loadel_0'            => sub { $self->is_loadel_0 },
        'is_loadel_1'            => sub { $self->is_loadel_1 },
        'is_loadel_2'            => sub { $self->is_loadel_2 },
        'is_neo_present'         => sub { $self->is_neo_present },
        'is_neo_absent'          => sub { $self->is_neo_absent },
        'is_bsd_present'         => sub { $self->is_bsd_present },
        'is_bsd_absent'          => sub { $self->is_bsd_absent },
        'is_potential_loacrit_0' => sub { $self->is_potential_loacrit_0 },
        'is_potential_loacrit_1' => sub { $self->is_potential_loacrit_1 },
        'is_potential_loacrit_2' => sub { $self->is_potential_loacrit_2 },
        'is_potential_loatam_0'  => sub { $self->is_potential_loatam_0 },
        'is_potential_loatam_1'  => sub { $self->is_potential_loatam_1 },
        'is_potential_loatam_2'  => sub { $self->is_potential_loatam_2 },
        'is_potential_loadel_0'  => sub { $self->is_potential_loadel_0 },
        'is_potential_loadel_1'  => sub { $self->is_potential_loadel_1 },
        'is_potential_loadel_2'  => sub { $self->is_potential_loadel_2 },
    };

    return $assay_dispatches;
}

sub _build_validation_dispatches {
    my ($self) = @_;

    my $validation_dispatches = {
        'loacrit' => sub { $self->_validate_assay('loacrit') },
        'loatam'  => sub { $self->_validate_assay('loatam') },
        'loadel'  => sub { $self->_validate_assay('loadel') },
        'neo'     => sub { $self->_validate_assay('neo') },
        'bsd'     => sub { $self->_validate_assay('bsd') },
    };

    return $validation_dispatches;
}

sub _build_allele_translation {
    my ($self) = @_;

    my $allele_translation = $self->allele_config->{'allele_translation'};

    return $allele_translation;
}

# this entry point is for where we just have an array of well ids
sub determine_allele_types_for_well_ids {
    my ( $self, $well_ids ) = @_;

    $self->well_ids($well_ids);

    # fetch array of well hashes from genotyping QC
    my @gqc_results = $self->model->get_genotyping_qc_well_data( \@{$well_ids}, 'dummy', $self->species );
    $self->well_genotyping_results_array( \@gqc_results );

    # TODO: get workflow calculation into summaries generation
    $self->_determine_workflow_for_wells();

    $self->_determine_allele_types();

    # return array of well hashes which contains the allele-type results
    return $self->well_genotyping_results_array;
}

# this entry point is for where we have a array of hashrefs of genotyping results (one hashref per well)
sub determine_allele_types_for_genotyping_results_array {
    my ( $self, $genotyping_results_array ) = @_;

    # store the genotyping results array of hashrefs
    $self->well_genotyping_results_array($genotyping_results_array);

    # TODO: get workflow calculation into summaries generation
    $self->_determine_workflow_for_wells();

    # determine allele types
    $self->_determine_allele_types();

    # return array of well hashes which contains the allele-type results
    return $self->well_genotyping_results_array;
}

# this entry point is for testing the logic, where the genotyping results array of well hashes is already
# set up and contains workflow and summaries table data
sub test_determine_allele_types_logic {
    my ( $self, $well_ids ) = @_;

    # determine allele types
    $self->_determine_allele_types();

    # return basic results hash
    return $self->well_allele_type_results;
}

sub _determine_allele_types {
    my ($self) = @_;

    $self->well_allele_type_results( {} );

    foreach my $well ( @{ $self->well_genotyping_results_array } ) {

        $self->current_well($well);
        $self->current_well_id( $well->{id} );

        my $current_allele_type = '';

        # attempt tp determine the allele type for this well and add the result into the output hashref
        try {
            $current_allele_type = $self->_determine_allele_type_for_well();
        }
        catch {
            my $exception_message = $_;
            $current_allele_type = "Failed allele determination, Exception: $exception_message";
        };

        # store full allele determination in well hash
        $well->{'allele_determination'} = $current_allele_type;

        # also reformat and store minimal version of allele determination for display in grids
        my $minimal_allele_type = $self->_minimised_allele_type($current_allele_type);
        $well->{'allele_type'} = $minimal_allele_type;

        # add result to minimal well / result hash
        $self->well_allele_type_results->{ $self->current_well_id } = $current_allele_type;
    }

    return;
}

sub _determine_workflow_for_wells {
    my ($self) = @_;

    # SQL for selecting the fields for determining workflows differs for EP_PICK and SEP_PICK plate types

    my @fepd_well_ids = ();
    my @sepd_well_ids = ();

    # first, group the well ids into FEPD and SEPD sets (will usually all be one type) so not
    # running the query multiple times

WELL_LOOP:
    foreach my $current_well ( @{ $self->well_genotyping_results_array } ) {

        my $current_well_id = $current_well->{'id'};

        unless ( defined $current_well_id ) { next WELL_LOOP; }

        my $curr_well_plate_type = $current_well->{'plate_type'};

        if ( defined $curr_well_plate_type && $curr_well_plate_type eq 'EP_PICK' ) {
            push( @fepd_well_ids, $current_well_id );
        }
        elsif ( defined $curr_well_plate_type && $curr_well_plate_type eq 'SEP_PICK' ) {
            push( @sepd_well_ids, $current_well_id );
        }
        else {

            # unusable plate type
            next WELL_LOOP;
        }
    }

    # select and write FEPD well data
    if ( scalar @fepd_well_ids > 0 ) {
        my $sql_query_fepd = $self->create_sql_select_summaries_fepd( ( \@fepd_well_ids ) );
        $self->_select_workflow_data($sql_query_fepd);
    }

    # select and write SEPD well data
    if ( scalar @sepd_well_ids > 0 ) {
        my $sql_query_sepd = $self->create_sql_select_summaries_sepd( ( \@sepd_well_ids ) );
        $self->_select_workflow_data($sql_query_sepd);
    }

    return;
}

sub _select_workflow_data {
    my ( $self, $sql_query ) = @_;

    try {
        my $sql_results = $self->run_select_query($sql_query);

        if ( defined $sql_results ) {

            # Calculate and set workflow for each well
            # Requires specific fields from summaries table

            my $well_results = {};

            # transfer results into hash
            foreach my $sql_result ( @{$sql_results} ) {

                my $curr_well_id = $sql_result->{'well_id'};
                $well_results->{$curr_well_id}->{'final_pick_recombinase_id'}
                    = $sql_result->{'final_pick_recombinase_id'} // '';
                $well_results->{$curr_well_id}->{'final_pick_cassette_resistance'}
                    = $sql_result->{'final_pick_cassette_resistance'} // '';
                $well_results->{$curr_well_id}->{'ep_well_recombinase_id'} = $sql_result->{'ep_well_recombinase_id'}
                    // '';
            }

            # loop through genotyping results array and copy across any results from the well_results hash
            # where there is a match of well id, and also calculate the workflow
        WELL_LOOP:
            foreach my $curr_well ( @{ $self->well_genotyping_results_array } ) {

                my $curr_well_id = $curr_well->{'id'};

                unless ( defined $curr_well_id ) { next WELL_LOOP; }

                # check if we have a result for this well id
                unless ( defined $well_results->{$curr_well_id} ) { next WELL_LOOP; }

                # store fields in well hash (or blank if not set)
                $curr_well->{'final_pick_recombinase_id'}
                    = $well_results->{$curr_well_id}->{'final_pick_recombinase_id'};
                $curr_well->{'final_pick_cassette_resistance'}
                    = $well_results->{$curr_well_id}->{'final_pick_cassette_resistance'};
                $curr_well->{'ep_well_recombinase_id'} = $well_results->{$curr_well_id}->{'ep_well_recombinase_id'};

                # calculate workflow for well
                $self->_calculate_workflow_for_well($curr_well);
            }
        }
    }
    catch {
        my $exception_message = $_;
        LIMS2::Exception::Implementation->throw(
            "Failed workflow determination for wells, exception : " . " : $exception_message" );
    };

    return;
}

sub _calculate_workflow_for_well {
    my ( $self, $current_well ) = @_;

    $current_well->{'workflow'} = 'unknown';

    # For the non-essential pathway they apply Cre to the vector to remove the critical region in the bsd cassette
    if ( $current_well->{'final_pick_recombinase_id'} eq 'Cre' ) {
        if ( $current_well->{'final_pick_cassette_resistance'} eq 'bsd' ) {

            # Means standard workflow for non-essential genes using Bsd cassette first
            $current_well->{'workflow'} = 'Ne1';    # Non-essential Bsd first
        }
    }
    else {

        # For the essential pathway they apply Flp to remove the neo cassette after the first electroporation
        if ( $current_well->{'ep_well_recombinase_id'} eq 'Flp' ) {
            if ( $current_well->{'final_pick_cassette_resistance'} eq 'neo' ) {
                $current_well->{'workflow'} = 'E';    # Essential genes workflow
            }
        }
        else {
            if ( $current_well->{'final_pick_cassette_resistance'} eq 'neo' ) {

                # Means alternate workflow for non-essential genes using Neo cassette first
                $current_well->{'workflow'} = 'Ne1a';    # Non-essential Neo first
            }
        }
    }

    return;
}

sub _determine_allele_type_for_well {
    my ($self) = @_;

    unless ( defined $self->current_well ) {
        return 'Failed: no current well set';
    }

    unless ( defined $self->current_well_id ) {
        return 'Failed: no current well id set';
    }

    unless ( defined $self->current_well->{'plate_type'} ) {
        return 'Failed: plate type not present for well id : ' . $self->current_well_id;
    }

    $self->current_well_stage( $self->current_well->{'plate_type'} );
    unless ( ( $self->current_well_stage eq 'EP_PICK' ) || ( $self->current_well_stage eq 'SEP_PICK' ) ) {
        return
              'Failed: stage type must be EP_PICK or SEP_PICK, found type '
            . $self->current_well_stage
            . ' for well '
            . $self->current_well_id;
    }

    unless ( defined $self->current_well->{'workflow'} ) {
        return 'Failed: workflow not present for well id : ' . $self->current_well_id;
    }

    $self->current_well_workflow( $self->current_well->{'workflow'} );

    $self->_create_assay_copy_number_string();

    # Attempt to find a match using normal copy number constraints
    my $allele_types_normal = $self->_determine_allele_type_for_well_with_constraints('normal');
    return $allele_types_normal if ( defined $allele_types_normal && ( $allele_types_normal ne '' ) );

    # Failed to find a match, so now retry with looser thresholds
    my $allele_types_loose = $self->_determine_allele_type_for_well_with_constraints('loose');
    if ( defined $allele_types_loose && ( $allele_types_loose ne '' ) ) {
        return $allele_types_loose;
    }
    else {
        my $pattern = $self->current_well->{'assay_pattern'};
        return
              'Failed: unknown allele pattern : '
            . $self->current_well_workflow . " "
            . $self->current_well_stage . " "
            . $pattern;
    }
}

sub _create_assay_copy_number_string {
    my ($self) = @_;

    my @pattern;

    # pull out the assay values
    foreach my $assay_name ( 'bsd', 'loacrit', 'loadel', 'loatam', 'neo' ) {
        push( @pattern,
            ( $assay_name . "<" . ( $self->current_well->{ $assay_name . '#copy_number' } // '-' ) . ">" ) );
    }

    my $pattern_string = join( ' ', (@pattern) );

    $self->current_well->{'assay_pattern'} = $pattern_string;

    return;
}

sub _determine_allele_type_for_well_with_constraints {
    my ( $self, $constraint_name ) = @_;

    $self->current_well_validation_msg('');
    unless ( $self->_validate_assays($constraint_name) ) {
        return 'Failed: validate assays : ' . $self->current_well_validation_msg;
    }

    my @allele_types;

    # Attempt to find a matching allele type using normal constraints
    my $tests
        = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{$constraint_name}
        ->{'tests'};

    foreach my $key ( keys %{$tests} ) {
        push( @allele_types, ( $self->allele_translation->{$key} ) )
            if ( $self->_is_allele_test( $constraint_name, $key ) );
    }

    if ( scalar @allele_types > 0 ) {
        return join( '; ', ( sort @allele_types ) );
    }
    else {
        return '';
    }
}

sub _is_allele_test {
    my ( $self, $constraint_name, $test_name ) = @_;

    # Get the specific logic for this particular workflow and scope into this method:
    my $logic_string
        = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{$constraint_name}
        ->{'tests'}->{$test_name};

    LIMS2::Exception->throw("allele checking: no tests logic string defined") unless ( defined $logic_string );

    # logic string looks like this: 'is_loacrit_1 AND is_loatam_1 AND is_loadel_0 AND is_neo_present AND is_bsd_present'
    # Get the parser to read this, interpret logic and run our coded methods "is_loacrit_1" etc
    my $parser = Parse::BooleanLogic->new();
    my $tree   = $parser->as_array($logic_string);

    my $callback = sub {
        my $self    = pop;
        my $operand = $_[0]->{'operand'};
        my $method  = $self->assay_dispatches->{$operand};
        return $method->();
    };

    my $result = $parser->solve( $tree, $callback, $self );

    return $result;
}

sub _minimised_allele_type {
    my ( $self, $current_allele_type ) = @_;

    # if string starts with Failed return fail
    if ( index( $current_allele_type, 'Failed: unknown allele pattern' ) != -1 ) {
        return 'unknown';
    }

    if ( index( $current_allele_type, 'Failed:' ) != -1 ) {
        return 'fail';
    }

    # if string contains 'potential ' replace with 'p'
    if ( index( $current_allele_type, 'potential ' ) != -1 ) {
        $current_allele_type =~ s/potential/p/g;
    }

    # off target types
    if ( index( $current_allele_type, 'offtarg ' ) != -1 ) {
        $current_allele_type =~ s/offtarg/ot/g;
    }

    # else return unchanged
    return $current_allele_type;
}

sub is_loacrit_0 {
    my ($self) = @_;

    my $loacrit_0_lower = $self->allele_config->{'thresholds'}->{'loacrit_0_lower_bound'};
    my $loacrit_0_upper = $self->allele_config->{'thresholds'}->{'loacrit_0_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loacrit_0_lower, $loacrit_0_upper, 'loacrit' );
}

sub is_loacrit_1 {
    my ($self) = @_;

    my $loacrit_1_lower = $self->allele_config->{'thresholds'}->{'loacrit_1_lower_bound'};
    my $loacrit_1_upper = $self->allele_config->{'thresholds'}->{'loacrit_1_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loacrit_1_lower, $loacrit_1_upper, 'loacrit' );
}

sub is_loacrit_2 {
    my ($self) = @_;

    my $loacrit_2_lower = $self->allele_config->{'thresholds'}->{'loacrit_2_lower_bound'};
    my $loacrit_2_upper = $self->allele_config->{'thresholds'}->{'loacrit_2_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loacrit_2_lower, $loacrit_2_upper, 'loacrit' );
}

sub is_loatam_0 {
    my ($self) = @_;

    my $loatam_0_lower = $self->allele_config->{'thresholds'}->{'loatam_0_lower_bound'};
    my $loatam_0_upper = $self->allele_config->{'thresholds'}->{'loatam_0_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loatam_0_lower, $loatam_0_upper, 'loatam' );
}

sub is_loatam_1 {
    my ($self) = @_;

    my $loatam_1_lower = $self->allele_config->{'thresholds'}->{'loatam_1_lower_bound'};
    my $loatam_1_upper = $self->allele_config->{'thresholds'}->{'loatam_1_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loatam_1_lower, $loatam_1_upper, 'loatam' );
}

sub is_loatam_2 {
    my ($self) = @_;

    my $loatam_2_lower = $self->allele_config->{'thresholds'}->{'loatam_2_lower_bound'};
    my $loatam_2_upper = $self->allele_config->{'thresholds'}->{'loatam_2_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loatam_2_lower, $loatam_2_upper, 'loatam' );
}

sub is_loadel_0 {
    my ($self) = @_;

    my $loadel_0_lower = $self->allele_config->{'thresholds'}->{'loadel_0_lower_bound'};
    my $loadel_0_upper = $self->allele_config->{'thresholds'}->{'loadel_0_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loadel_0_lower, $loadel_0_upper, 'loadel' );
}

sub is_loadel_1 {
    my ($self) = @_;

    my $loadel_1_lower = $self->allele_config->{'thresholds'}->{'loadel_1_lower_bound'};
    my $loadel_1_upper = $self->allele_config->{'thresholds'}->{'loadel_1_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loadel_1_lower, $loadel_1_upper, 'loadel' );
}

sub is_loadel_2 {
    my ($self) = @_;

    my $loadel_2_lower = $self->allele_config->{'thresholds'}->{'loadel_2_lower_bound'};
    my $loadel_2_upper = $self->allele_config->{'thresholds'}->{'loadel_2_upper_bound'};

    return $self->is_assay_copy_number_in_rng( $loadel_2_lower, $loadel_2_upper, 'loadel' );
}

sub is_potential_loacrit_0 {
    my ($self) = @_;

    my $loacrit_0_lower = $self->allele_config->{'thresholds'}->{'loacrit_0_lower_bound_loose'};
    my $loacrit_0_upper = $self->allele_config->{'thresholds'}->{'loacrit_0_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loacrit_0_lower, $loacrit_0_upper, 'loacrit' );
}

sub is_potential_loacrit_1 {
    my ($self) = @_;

    my $loacrit_1_lower = $self->allele_config->{'thresholds'}->{'loacrit_1_lower_bound_loose'};
    my $loacrit_1_upper = $self->allele_config->{'thresholds'}->{'loacrit_1_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loacrit_1_lower, $loacrit_1_upper, 'loacrit' );
}

sub is_potential_loacrit_2 {
    my ($self) = @_;

    my $loacrit_2_lower = $self->allele_config->{'thresholds'}->{'loacrit_2_lower_bound_loose'};
    my $loacrit_2_upper = $self->allele_config->{'thresholds'}->{'loacrit_2_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loacrit_2_lower, $loacrit_2_upper, 'loacrit' );
}

sub is_potential_loatam_0 {
    my ($self) = @_;

    my $loatam_0_lower = $self->allele_config->{'thresholds'}->{'loatam_0_lower_bound_loose'};
    my $loatam_0_upper = $self->allele_config->{'thresholds'}->{'loatam_0_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loatam_0_lower, $loatam_0_upper, 'loatam' );
}

sub is_potential_loatam_1 {
    my ($self) = @_;

    my $loatam_1_lower = $self->allele_config->{'thresholds'}->{'loatam_1_lower_bound_loose'};
    my $loatam_1_upper = $self->allele_config->{'thresholds'}->{'loatam_1_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loatam_1_lower, $loatam_1_upper, 'loatam' );
}

sub is_potential_loatam_2 {
    my ($self) = @_;

    my $loatam_2_lower = $self->allele_config->{'thresholds'}->{'loatam_2_lower_bound_loose'};
    my $loatam_2_upper = $self->allele_config->{'thresholds'}->{'loatam_2_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loatam_2_lower, $loatam_2_upper, 'loatam' );
}

sub is_potential_loadel_0 {
    my ($self) = @_;

    my $loadel_0_lower = $self->allele_config->{'thresholds'}->{'loadel_0_lower_bound_loose'};
    my $loadel_0_upper = $self->allele_config->{'thresholds'}->{'loadel_0_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loadel_0_lower, $loadel_0_upper, 'loadel' );
}

sub is_potential_loadel_1 {
    my ($self) = @_;

    my $loadel_1_lower = $self->allele_config->{'thresholds'}->{'loadel_1_lower_bound_loose'};
    my $loadel_1_upper = $self->allele_config->{'thresholds'}->{'loadel_1_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loadel_1_lower, $loadel_1_upper, 'loadel' );
}

sub is_potential_loadel_2 {
    my ($self) = @_;

    my $loadel_2_lower = $self->allele_config->{'thresholds'}->{'loadel_2_lower_bound_loose'};
    my $loadel_2_upper = $self->allele_config->{'thresholds'}->{'loadel_2_upper_bound_loose'};

    return $self->is_assay_copy_number_in_rng( $loadel_2_lower, $loadel_2_upper, 'loadel' );
}

sub is_neo_present {
    my ($self) = @_;

    my $neo_threshold = $self->allele_config->{'thresholds'}->{'neo_threshold'};

    return $self->is_marker_present( $neo_threshold, 'neo' );
}

sub is_neo_absent {
    my ($self) = @_;

    return !$self->is_neo_present();
}

sub is_bsd_present {
    my ($self) = @_;

    my $bsd_threshold = $self->allele_config->{'thresholds'}->{'bsd_threshold'};

    return $self->is_marker_present( $bsd_threshold, 'bsd' );
}

sub is_bsd_absent {
    my ($self) = @_;

    return !$self->is_bsd_present();
}

sub is_assay_copy_number_in_rng {
    my ( $self, $min, $max, $assay_name ) = @_;

    my $value = $self->current_well->{ $assay_name . '#copy_number' };

    if ( defined $value && $value ne '-' ) {
        return $self->is_value_in_range( $min, $max, $value );
    }
    else {
        return 0;
    }
}

sub is_marker_present {
    my ( $self, $threshold, $marker ) = @_;

    my $value = $self->current_well->{ $marker . '#copy_number' };

    if ( ( defined $value ) && ( $value ne '-' ) && ( $value >= $threshold ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_value_in_range {
    my ( $self, $min, $max, $value ) = @_;

    if ( ( $value >= $min ) && ( $value <= $max ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _validate_assays {
    my ( $self, $constraint_name ) = @_;

    LIMS2::Exception->throw("validate assays: no current well set")          unless $self->current_well_id;
    LIMS2::Exception->throw("validate assays: no current well workflow set") unless $self->current_well_workflow;
    LIMS2::Exception->throw("validate assays: no current well stage set")    unless $self->current_well_stage;

    # Get the specific logic for this particular workflow and scope into this method:
    my $validation_logic_string
        = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{$constraint_name}
        ->{'validation'}->{'assays'};

    LIMS2::Exception->throw("validation: no validation logic string defined")
        unless ( defined $validation_logic_string );

    # logic string looks like this: 'loacrit AND loatam AND neo'
    # Get the parser to read this, interpret logic and run correct validate assay methods
    my $parser = Parse::BooleanLogic->new();
    my $tree   = $parser->as_array($validation_logic_string);

    my $callback = sub {
        my $self    = pop;
        my $operand = $_[0]->{'operand'};
        my $method  = $self->validation_dispatches->{$operand};
        return $method->();
    };

    my $result = $parser->solve( $tree, $callback, $self );

    return $result;
}

sub _validate_assay {
    my ( $self, $assay_name ) = @_;

    # print "validating assay : $assay_name\n";

    my $cn  = $self->current_well->{ $assay_name . '#copy_number' };
    my $cnr = $self->current_well->{ $assay_name . '#copy_number_range' };

    #TODO: add checks on confidence and vic
    #my $conf = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#confidence' };
    #my $vic = $self->well_genotyping_results->{ $self->current_well_id }->{ $assay_name . '#vic' };

    unless ( defined $cn && $cn ne '-' ) {

        # LIMS2::Exception->throw( "$assay_name assay validation: Copy Number not present" );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . "$assay_name assay validation: Copy Number not present" );
        return 0;
    }

    unless ( defined $cnr && $cnr ne '-' ) {

        # LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range not present" );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . "$assay_name assay validation: Copy Number Range not present" );
        return 0;
    }

    unless ( $cnr <= 0.4 ) {

        # LIMS2::Exception->throw( "$assay_name assay validation: Copy Number Range above threshold" );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . "$assay_name assay validation: Copy Number Range above threshold" );
        return 0;
    }

    # TODO: add validations for confidence and vic

    return 1;
}

# Generic method to run select SQL
sub run_select_query {
    my ( $self, $sql_query ) = @_;

    my $sql_result = $self->model->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare($sql_query);
            $sth->execute or die "Unable to execute query: $dbh->errstr\n";
            $sth->fetchall_arrayref(
                {

                }
            );
        }
    );

    return $sql_result;
}

sub create_sql_select_summaries_fepd {
    my ( $self, $well_ids ) = @_;

    $well_ids = join( ',', @{$well_ids} );

    my $sql_query = <<"SQL_END";
select distinct ep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, ep_well_recombinase_id
from summaries
where ep_pick_well_id in ( $well_ids )
SQL_END

    return $sql_query;
}

sub create_sql_select_summaries_sepd {
    my ( $self, $well_ids ) = @_;

    $well_ids = join( ',', @{$well_ids} );

    my $sql_query = <<"SQL_END";
select distinct sep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, ep_well_recombinase_id
from summaries
where sep_pick_well_id in ( $well_ids )
and ep_pick_well_id > 0
SQL_END

    return $sql_query;
}

1;

__END__
