package LIMS2::Model::Util::AlleleDetermination;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::AlleleDetermination::VERSION = '0.387';
}
## use critic


use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::AlleleDetermination

=head1 DESCRIPTION

Calculates the Allele Types for sets of wells using their genotyping QC information.
Also generates an overall calculated genotyping pass for the well.

=cut

use Moose;
use Try::Tiny;
use LIMS2::Exception;
use Parse::BooleanLogic;
use Log::Log4perl qw( :easy );

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# flag for testing mode
has is_in_test_mode => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default => 0,
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
    isa => 'Maybe[HashRef]',
);

has current_well_id => (
    is       => 'rw',
    isa      => 'Maybe[Int]',
    required => 0,
);

has current_well_workflow => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    required => 0,
);

has current_well_stage => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    required => 0,
);

has current_well_validation_msg => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    required => 0,
);

has allele_config => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_allele_config',
);

has dispatches => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub BUILD {
    my ( $self ) = @_;
    return;
}

=head2 _build_allele_config

Create an internal hash from the allele configuration file.

=cut
sub _build_allele_config {
    my ( $self ) = @_;

    my $conf_parser = Config::Scoped->new(
        file     => $ENV{LIMS2_ALLELE_DET_CONFIG},
        warnings => { permissions => 'off' }
    );

    my $allele_config = $conf_parser->parse;

    return $allele_config;
}

=head2 _build_dispatches

Build the dispatches table to call internal methods based on the contents of logic strings in the configuration file.

=cut
sub _build_dispatches {
    my ( $self ) = @_;

    my $dispatches = {
        'is_loacrit_0'           => sub { $self->_is_loacrit_0 },
        'is_potential_loacrit_0' => sub { $self->_is_potential_loacrit_0 },
        'is_loacrit_1'           => sub { $self->_is_loacrit_1 },
        'is_potential_loacrit_1' => sub { $self->_is_potential_loacrit_1 },
        'is_loacrit_2'           => sub { $self->_is_loacrit_2 },
        'is_potential_loacrit_2' => sub { $self->_is_potential_loacrit_2 },
        'is_loatam_0'            => sub { $self->_is_loatam_0 },
        'is_potential_loatam_0'  => sub { $self->_is_potential_loatam_0 },
        'is_loatam_1'            => sub { $self->_is_loatam_1 },
        'is_potential_loatam_1'  => sub { $self->_is_potential_loatam_1 },
        'is_loatam_2'            => sub { $self->_is_loatam_2 },
        'is_potential_loatam_2'  => sub { $self->_is_potential_loatam_2 },
        'is_loadel_0'            => sub { $self->_is_loadel_0 },
        'is_potential_loadel_0'  => sub { $self->_is_potential_loadel_0 },
        'is_loadel_1'            => sub { $self->_is_loadel_1 },
        'is_potential_loadel_1'  => sub { $self->_is_potential_loadel_1 },
        'is_loadel_2'            => sub { $self->_is_loadel_2 },
        'is_potential_loadel_2'  => sub { $self->_is_potential_loadel_2 },
        'is_cre_0'               => sub { $self->_is_cre_0 },
        'is_potential_cre_0'     => sub { $self->_is_potential_cre_0 },
        'is_cre_1'               => sub { $self->_is_cre_1 },
        'is_potential_cre_1'     => sub { $self->_is_potential_cre_1 },
        'is_chry_0'              => sub { $self->_is_chry_0 },
        'is_potential_chry_0'    => sub { $self->_is_potential_chry_0 },
        'is_chry_1'              => sub { $self->_is_chry_1 },
        'is_potential_chry_1'    => sub { $self->_is_potential_chry_1 },
        'is_chry_2'              => sub { $self->_is_chry_2 },
        'is_potential_chry_2'    => sub { $self->_is_potential_chry_2 },
        'is_chr8a_0'             => sub { $self->_is_chr8a_0 },
        'is_potential_chr8a_0'   => sub { $self->_is_potential_chr8a_0 },
        'is_chr8a_1'             => sub { $self->_is_chr8a_1 },
        'is_potential_chr8a_1'   => sub { $self->_is_potential_chr8a_1 },
        'is_chr8a_2'             => sub { $self->_is_chr8a_2 },
        'is_potential_chr8a_2'   => sub { $self->_is_potential_chr8a_2 },
        'not_is_chr8a_2'         => sub { !$self->_is_chr8a_2 },
        'is_neo_present'         => sub { $self->_is_neo_present },
        'is_neo_absent'          => sub { !$self->_is_neo_present },
        'is_bsd_present'         => sub { $self->_is_bsd_present },
        'is_bsd_absent'          => sub { !$self->_is_bsd_present },
        'is_puro_present'        => sub { $self->_is_puro_present },
        'is_puro_absent'         => sub { !$self->_is_puro_present },
        'is_lrpcr_pass'          => sub { $self->_is_lrpcr_pass },

        'valid_loacrit'          => sub { $self->_validate_assay('loacrit') },
        'valid_loatam'           => sub { $self->_validate_assay('loatam') },
        'valid_loadel'           => sub { $self->_validate_assay('loadel') },
        'not_valid_loadel'       => sub { !$self->_validate_assay('loadel') },
        'valid_neo'              => sub { $self->_validate_assay('neo') },
        'valid_bsd'              => sub { $self->_validate_assay('bsd') },
        'valid_cre'              => sub { $self->_validate_assay('cre') },
        'valid_puro'             => sub { $self->_validate_assay('puro') },
        'valid_lrpcr'            => sub { $self->_validate_primers('lrpcr') },
        'valid_chry'             => sub { $self->_validate_assay('chry') },
        'valid_chr8a'            => sub { $self->_validate_assay('chr8a') },

        'exists_loadel'          => sub { $self->_validate_assay_exists('loadel') },
        'not_exists_loadel'      => sub { !$self->_validate_assay_exists('loadel') },
        'exists_loacrit'         => sub { $self->_validate_assay_exists('loacrit') },
        'not_exists_loacrit'     => sub { !$self->_validate_assay_exists('loacrit') },
    };

    return $dispatches;
}

=head2 determine_allele_types_for_well_ids

This entry point is for where we just have an array of well ids.

=cut
sub determine_allele_types_for_well_ids {
    my ( $self, $well_ids ) = @_;

    $self->well_ids($well_ids);

    # fetch array of well hashes from genotyping QC
    my @gqc_results = $self->model->get_genotyping_qc_well_data( \@{$well_ids}, 'dummy', $self->species );
    $self->well_genotyping_results_array( \@gqc_results );

    # TODO: get workflow calculation into summaries generation
    $self->_determine_workflow_for_wells();

    $self->_determine_allele_types_for_wells();

    $self->_determine_genotyping_pass_for_wells();

    # return array of well hashes which contains the allele-type results
    return $self->well_genotyping_results_array;
}

=head2 determine_allele_types_for_genotyping_results_array

This entry point is for where we have a array of hashrefs of genotyping results (one hashref per well).

=cut
sub determine_allele_types_for_genotyping_results_array {
    my ( $self, $genotyping_results_array ) = @_;

    # store the genotyping results array of hashrefs
    $self->well_genotyping_results_array($genotyping_results_array);

    # TODO: get workflow calculation into summaries generation
    $self->_determine_workflow_for_wells();

    # determine allele types
    $self->_determine_allele_types_for_wells( 0 );

    $self->_determine_genotyping_pass_for_wells();

    # return array of well hashes which contains the allele-type results
    return $self->well_genotyping_results_array;
}

=head2 test_determine_allele_types_logic

This entry point is for testing the logic, where the genotyping results array of well hashes is already
set up and contains workflow and summaries table data.

=cut
sub test_determine_allele_types_logic {
    my ( $self ) = @_;

    $self->is_in_test_mode( 1 );

    # determine allele types
    $self->_determine_allele_types_for_wells();

    $self->_determine_genotyping_pass_for_wells();

    # return array of well hashes which contains the allele-type results
    return $self->well_genotyping_results_array;
}

=head2 _determine_allele_types_for_wells

Determine the allele types for all the wells.

=cut
sub _determine_allele_types_for_wells {
    my ( $self ) = @_;

    $self->well_allele_type_results( {} );

    $self->_initialise_current_well_attributes();

    foreach my $well ( @{ $self->well_genotyping_results_array } ) {

        $self->current_well($well);
        $self->current_well_id( $well->{id} );

        my $current_allele_type = '';

        # attempt to determine the allele type for this well and add the result into the output hashref
        try {
            $current_allele_type = $self->_determine_allele_type_for_well();
        }
        catch {
            my $exception_message = $_;
            $current_allele_type = 'Failed allele determination. Exception: '.$exception_message;
            WARN( 'Failed allele determination. Exception: '.$exception_message );
        };

        # store full allele determination in well hash
        $well->{ 'allele_determination' } = $current_allele_type;

        # also reformat and store minimal version of allele determination for display in grids
        my $minimal_allele_type = $self->_minimised_allele_type($current_allele_type);
        $well->{ 'allele_type' } = $minimal_allele_type;

        # add result to minimal well / result hash
        $self->well_allele_type_results->{ $self->current_well_id } = $current_allele_type;
    }

    return;
}

=head2 _determine_workflow_for_wells

Determine the laboratory workflow for each of the wells.

=cut
sub _determine_workflow_for_wells {
    my ( $self ) = @_;

    # SQL for selecting the fields for determining workflows differs for EP_PICK, SEP_PICK and PIQ plate types
    # First group the well ids into FEPD, SEPD and PIQ arrays (will usually all be one type) so not
    # running the SQL query multiple times

    my @fepd_well_ids = ();
    my @sepd_well_ids = ();
    my @piq_well_ids  = ();

    $self->_initialise_current_well_attributes();

    foreach my $current_well ( @{ $self->well_genotyping_results_array } ) {

        my $current_well_id         = $current_well->{ 'id' };
        my $current_well_plate_type = $current_well->{ 'plate_type' };
        unless ( defined $current_well_id && defined $current_well_plate_type ) {
            # no plate type found, cannot determine workflow for this well
            $current_well->{ 'workflow' } = 'unknown';
            next;
        }

        if ( $current_well_plate_type eq 'EP_PICK' ) {
            push( @fepd_well_ids, $current_well_id );
        }
        elsif ( $current_well_plate_type eq 'SEP_PICK' ) {
            push( @sepd_well_ids, $current_well_id );
        }
        elsif ( $current_well_plate_type eq 'PIQ' ) {
            push( @piq_well_ids, $current_well_id );
        }
        else {
            # unusable plate type, cannot determine workflow for this well
            $current_well->{ 'workflow' } = 'unknown';
        }
    }

    # select and write FEPD well data (if any)
    if ( scalar @fepd_well_ids > 0 ) {
        my $sql_query_fepd = $self->_create_sql_select_summaries_fepd( ( \@fepd_well_ids ) );
        $self->_select_workflow_data($sql_query_fepd);
    }

    # select and write SEPD well data (if any)
    if ( scalar @sepd_well_ids > 0 ) {
        my $sql_query_sepd = $self->_create_sql_select_summaries_sepd( ( \@sepd_well_ids ) );
        $self->_select_workflow_data($sql_query_sepd);
    }

    # select and write PIQ well data (if any)
    if ( scalar @piq_well_ids > 0 ) {
        my $sql_query_piq = $self->_create_sql_select_summaries_piq( ( \@piq_well_ids ) );
        $self->_select_workflow_data($sql_query_piq);
    }

    return;
}

=head2 _select_workflow_data

Select the workflow data for the wells.

=cut
sub _select_workflow_data {
    my ( $self, $sql_query ) = @_;

    try {
        my $sql_results = $self->_run_select_query($sql_query);

        if ( defined $sql_results ) {
            my $well_results = {};

            # transfer results into hash ( set to blank if empty field )
            foreach my $sql_result ( @{$sql_results} ) {
                my $current_sql_well_id = $sql_result->{ 'well_id' };
                $well_results->{ $current_sql_well_id }->{ 'final_pick_recombinase_id' }      = $sql_result->{ 'final_pick_recombinase_id' } // '';
                $well_results->{ $current_sql_well_id }->{ 'final_pick_cassette_resistance' } = $sql_result->{ 'final_pick_cassette_resistance' } // '';
                $well_results->{ $current_sql_well_id }->{ 'final_pick_cassette_cre' }        = $sql_result->{ 'final_pick_cassette_cre' } // '';
                $well_results->{ $current_sql_well_id }->{ 'ep_well_recombinase_id' }         = $sql_result->{ 'ep_well_recombinase_id' } // '';
            }

            # now loop through genotyping results array and copy across any results from the well_results hash, and calculate workflow
            foreach my $current_gr_well ( @{ $self->well_genotyping_results_array } ) {
                my $current_gr_well_id = $current_gr_well->{ 'id' };

                # check for whether there is a result for this well ID
                unless ( defined $current_gr_well_id && defined $well_results->{ $current_gr_well_id } ) { next; }

                # store fields in well hash (or blank if not set)
                $current_gr_well->{ 'final_pick_recombinase_id' }       = $well_results->{ $current_gr_well_id }->{ 'final_pick_recombinase_id' };
                $current_gr_well->{ 'final_pick_cassette_resistance' }  = $well_results->{ $current_gr_well_id }->{ 'final_pick_cassette_resistance' };
                $current_gr_well->{ 'final_pick_cassette_cre' }         = $well_results->{ $current_gr_well_id }->{ 'final_pick_cassette_cre' };
                $current_gr_well->{ 'ep_well_recombinase_id' }          = $well_results->{ $current_gr_well_id }->{ 'ep_well_recombinase_id' };

                # calculate workflow for well
                $self->_calculate_workflow_for_well( $current_gr_well );
            }
        }
    }
    catch {
        my $exception_message = $_;
        LIMS2::Exception::Implementation->throw(
            "Failed workflow determination for wells. Exception : " . " : $exception_message" );
    };

    return;
}

=head2 _calculate_workflow_for_well

Calculate which laborratory workflow applies for this well.

=cut
sub _calculate_workflow_for_well {
    my ( $self, $current_well ) = @_;

    $current_well->{ 'workflow' } = 'unknown';

    my $fpick_recomb   = $current_well->{ 'final_pick_recombinase_id' };
    my $fpick_cass_res = $current_well->{ 'final_pick_cassette_resistance' };
    my $fpick_cass_cre = $current_well->{ 'final_pick_cassette_cre' };
    my $ep_recomb      = $current_well->{ 'ep_well_recombinase_id' };

    if ( $fpick_cass_cre eq '1' ) {
        # Heterozygous Cre knockin workflows
        if ( $ep_recomb eq 'Dre' ) {
            # For the workflow for Dre'd Cre Knockin genes they apply Dre to the cassette to excise the puromycin resistance and promoter
            $current_well->{ 'workflow' } = 'CreKiDre';
            return;
        }
        else {
            # For the workflow for non-Dre'd Cre Knockin genes they do not apply Dre so leave in the puromycin resistance and promoter
            $current_well->{ 'workflow' } = 'CreKi';
            return;
        }
    }
    else {
        if ( $fpick_recomb eq 'Cre' ) {
            if ( $fpick_cass_res eq 'bsd' ) {
                # For the workflow for non-essential homozygous genes they apply Cre to the vector to remove the critical region in the bsd cassette
                $current_well->{ 'workflow' } = 'Ne1';
                return;
            }
        }
        else {
            if ( $fpick_cass_res eq 'neo' ) {
                if ( $ep_recomb eq 'Flp' ) {
                    # For the workflow for essential homozygous genes they apply Flp to remove the neo cassette after the first electroporation
                    $current_well->{ 'workflow' } = 'E';
                    return;
                }
                else {
                    # For the alternate workflow for non-essential homozygous genes using Neo cassette first
                    $current_well->{ 'workflow' } = 'Ne1a';
                    return;
                }
            }
        }
    }

    return;
}

=head2 _determine_allele_type_for_well

Determine the allele type for the well based on workflow, stage and genotyping assay results.

=cut
sub _determine_allele_type_for_well {
    my ( $self ) = @_;

    unless ( defined $self->current_well ) { return 'Failed: no current well set'; }
    unless ( defined $self->current_well_id ) { return 'Failed: no current well id set'; }
    unless ( defined $self->current_well->{ 'plate_type' } ) { return 'Failed: plate type not present'; }

    $self->current_well_stage( $self->current_well->{ 'plate_type' } );

    unless ( $self->current_well_stage ~~ [ qw( EP_PICK SEP_PICK PIQ ) ] ) { return 'N/A'; }
    unless ( defined $self->current_well->{ 'workflow' } ) { return 'Failed: workflow not present'; }

    $self->current_well_workflow( $self->current_well->{ 'workflow' } );

    unless ( $self->is_in_test_mode ) {
        unless ( $self->_well_has_qc_data() ) { return 'Failed: no qc data for well'; }
    }

    $self->_create_assay_summary_string();

    # Attempt to find a match using normal copy number constraints
    my $allele_types_normal = $self->_determine_allele_type_for_well_with_constraints( 'normal' );
    if ( defined $allele_types_normal && ( $allele_types_normal ne '' ) ) {
        return $allele_types_normal;
    }

    # Failed to find a match, so now retry with looser thresholds
    my $allele_types_loose = $self->_determine_allele_type_for_well_with_constraints('loose');
    if ( defined $allele_types_loose && ( $allele_types_loose ne '' ) ) {
        return $allele_types_loose;
    }
    else {
        return
              'Failed: unknown allele pattern : '
            . $self->current_well_workflow . ' '
            . $self->current_well_stage . ' '
            . $self->current_well->{ 'assay_pattern' };
    }
}

=head2 _well_has_qc_data

Check if well has genotyping qc data.

=cut
sub _well_has_qc_data {
    my ( $self ) = @_;

    my $has_qc_data = 0;

    try {
        my $sql_query = $self->_create_sql_select_qc_data( $self->current_well_id );
        my $sql_results = $self->_run_select_query($sql_query);
        if ( defined $sql_results && (scalar @{ $sql_results } ) > 0 ) {
            $has_qc_data = 1;
        }
    }
    catch {
        my $exception_message = $_;
        LIMS2::Exception->throw("Failed has_qc_data check. Exception: $exception_message");
    };

    $self->current_well->{ 'has_qc_data' } = $has_qc_data;
    return $has_qc_data;
}

=head2 _create_assay_summary_string

Summarise the assay results for grid display.

=cut
sub _create_assay_summary_string {
    my ( $self ) = @_;

    my @pattern;

    if ( $self->current_well_workflow ~~ [ qw( CreKi CreKiDre ) ] ) {
        # build the summary for Cre Knockin workflows
        foreach my $assay_name ( 'cre', 'puro', 'loadel', 'loacrit' ) {
            push( @pattern,
                ( $assay_name . ':' . ( $self->current_well->{ $assay_name . '#copy_number' } // '-' ) ) );
        }
        foreach my $lrpcr_val ( 'gr3', 'gf3', 'gr4', 'gf4' ) {
            my $lrpcr_val_string = $lrpcr_val . ':' . ( $self->current_well->{ $lrpcr_val } // '-' );
            # DEBUG( 'curr well id= ' . $self->current_well_id() . ' lrpcr_val_string=' . $lrpcr_val_string );
            push( @pattern, $lrpcr_val_string );
        }
    }
    else {
        # build the summary for homozygous workflows
        foreach my $assay_name ( 'bsd', 'loacrit', 'loadel', 'loatam', 'neo' ) {
            push( @pattern,
                ( $assay_name . ':' . ( $self->current_well->{ $assay_name . '#copy_number' } // '-' ) ) );
        }
    }

    my $pattern_string = join( ' ', (@pattern) );

    $self->current_well->{ 'assay_pattern' } = $pattern_string;

    return;
}

=head2 _determine_allele_type_for_well_with_constraints

Determine the allele type for a specific well and constraint type (e.g. normal, loose).

=cut
sub _determine_allele_type_for_well_with_constraints {
    my ( $self, $constraint_name ) = @_;

    $self->current_well_validation_msg('');
    unless ( $self->_validate_assays( $constraint_name ) ) {
        return 'Failed: validate assays : ' . $self->current_well_validation_msg;
    }

    my @allele_types;

    # Attempt to find a matching allele type using normal constraints
    my $tests = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ $constraint_name }->{ 'tests' };

    unless ( defined $tests ) { LIMS2::Exception->throw("determine allele type for well: no tests defined in config") };

    foreach my $key ( keys %{ $tests } ) {

        # Get the specific logic for this particular workflow and scope into this method:
        my $logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ $constraint_name }->{ 'tests' }->{ $key };

        LIMS2::Exception->throw("determine allele type: no tests logic string defined for test " . $key ) unless ( defined $logic_string && $logic_string ne '' );

        push( @allele_types, ( $self->allele_config->{ 'allele_translation' }->{ $key } ) )
            if ( $self->_is_allele_test( $logic_string ) );
    }

    if ( scalar @allele_types > 0 ) {
        return join( '; ', ( sort @allele_types ) );
    }
    else {
        return '';
    }
}

=head2 _is_allele_test

Determine the overall result of all the individual tests in one allele logic string.

=cut
sub _is_allele_test {
    my ( $self, $logic_string ) = @_;

    LIMS2::Exception->throw( "allele test: no tests logic string defined" ) unless ( defined $logic_string && $logic_string ne '' );

    # DEBUG ( 'Allele test logic string = ' . $logic_string );

    # logic string looks like this: 'is_loacrit_1 AND is_loatam_1 AND is_loadel_0 AND ( is_neo_present OR is_bsd_present )'
    # Get the parser to read this, interpret logic and run our coded methods "is_loacrit_1" etc
    my $parser = Parse::BooleanLogic->new();
    my $tree   = $parser->as_array( $logic_string );

    my $callback = sub {
        my $self    = pop;
        my $operand = $_[0]->{ 'operand' };

        # DEBUG ( 'operand = <' . $operand . '>' );

        my $method  = $self->dispatches->{ $operand };
        return $method->();
    };

    my $result = $parser->solve( $tree, $callback, $self );

    return $result;
}

=head2 _minimised_allele_type

Minimise the returned allele type for grid display purposes (small column width).

=cut
sub _minimised_allele_type {
    my ( $self, $current_allele_type ) = @_;

    # if string starts with Failed return fail
    if ( index( $current_allele_type, 'Failed: unknown allele pattern' ) != -1 ) {
        return 'unknown';
    }

    if ( index( $current_allele_type, 'Failed' ) != -1 ) {
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

=head2 _determine_genotyping_pass_for_wells

Determine the overall genotyping passes for all the wells.

=cut
sub _determine_genotyping_pass_for_wells {
    my ( $self ) = @_;

    # this has to decide if the overall result is a pass (distribute) or fail
     $self->_initialise_current_well_attributes();

    foreach my $curr_well_hash ( @{ $self->well_genotyping_results_array } ) {

        $self->current_well( $curr_well_hash );
        $self->current_well_id( $curr_well_hash->{ 'id' } );

        my $current_genotyping_pass = 'fail';

        # set version number of ruleset
        $curr_well_hash->{ 'accepted_rules_version' } = $self->allele_config->{ 'ruleset' }->{ 'version' };

        # attempt to determine the genotyping pass for this well and add the result into the output hashref
        try {
            $current_genotyping_pass = $self->_determine_genotyping_pass_for_well();
        }
        catch {
            my $exception_message = $_;
            $curr_well_hash->{ 'genotyping_pass_error_message' } = 'Failed genotyping pass determination. Exception: '. $exception_message;
            ERROR( 'Failed genotyping pass determination. Exception: '. $exception_message );
        };

        # store calculated genotyping pass in well hash
        $curr_well_hash->{ 'genotyping_pass' } = $current_genotyping_pass;

        # DEBUG ( "well id " . $self->current_well_id . " well genotyping pass = " . $curr_well_hash->{ 'genotyping_pass' } );
    }

    return;
}

=head2 _determine_genotyping_pass_for_well

Determine the genotyping pass for the current well.

=cut
sub _determine_genotyping_pass_for_well {
    my ( $self ) = @_;

    # DEBUG ( 'In _determine_genotyping_pass_for_well method' );

    LIMS2::Exception->throw( 'Failed: no current well set' ) unless ( defined $self->current_well );
    LIMS2::Exception->throw( 'Failed: no current well id set' ) unless ( defined $self->current_well_id );
    LIMS2::Exception->throw( 'Failed: plate type not present for well id : ' . $self->current_well_id ) unless ( defined $self->current_well->{ 'plate_type' } );

    $self->current_well_stage( $self->current_well->{ 'plate_type' } );

    LIMS2::Exception->throw( 'Failed: Plate type unusable' ) unless ( $self->current_well_stage ~~ [ qw( EP_PICK SEP_PICK PIQ ) ] );
    LIMS2::Exception->throw( 'Failed: Workflow not present' ) unless ( defined $self->current_well->{ 'workflow' } );

    $self->current_well_workflow( $self->current_well->{ 'workflow' } );

    LIMS2::Exception->throw( 'Failed: Allele type not present' ) unless ( defined $self->current_well->{ 'allele_determination' } );

    # If the well allele type is a 'fail' return false
    my $curr_well_allele_det = $self->current_well->{ 'allele_type' };
    # DEBUG ( 'curr_well_allele_det = ' . $curr_well_allele_det );
    if ( !defined $curr_well_allele_det || $curr_well_allele_det eq 'fail' || $curr_well_allele_det eq 'unknown' ) { return 'fail'; }

    # Check if the allele type matches one of the allowed types according to the config file
    unless ( $self->_is_allele_type_valid_for_genotyping_pass() ) { return 'fail'; };

    # Attempt to find a pass result using the test criteria from the config file
    my $genotyping_pass = $self->_apply_additional_genotyping_pass_criteria();

     # DEBUG ( "well id " . $self->current_well_id . " genotyping pass = " . $genotyping_pass );

    # update the well accepted value
    $self->_set_calculated_well_accepted_value( $genotyping_pass );

    return $genotyping_pass;
}

=head2 _is_allele_type_valid_for_genotyping_pass

Determine whether the allele type is a valid type to be a genotyping pass

=cut
sub _is_allele_type_valid_for_genotyping_pass {
    my ( $self ) = @_;

    # DEBUG ( 'In _is_allele_type_valid_for_genotyping_pass method' );

    # Fetch the list of genotyping pass allowed allele types from the config
    # e.g. 'tm1_wt OR tm1_wt_lrpcr OR tm1_1_wt OR tm1_1_wt_lrpcr OR potential_tm1_wt OR potential_tm1_wt_lrpcr OR potential_tm1_1_wt OR potential_tm1_1_wt_lrpcr'
    my $allowed_types_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'genotyping_pass' }->{ 'types_allowed' }->{ 'allele_types' };
    my @allowed_types_array = split( /\sOR\s/, $allowed_types_string );
    my @conv_allowed_types_array = ();
    foreach my $allowed_type ( @allowed_types_array ) {
        push( @conv_allowed_types_array, ( $self->allele_config->{ 'allele_translation' }->{ $allowed_type } ) );
    }

    LIMS2::Exception->throw( 'Failed: No allowed allele types in config so cannot determine genotyping pass' ) unless ( scalar @conv_allowed_types_array > 0 );

    # DEBUG( 'config string = ' . $allowed_types_string );
    # DEBUG( 'config as array = ' . join( ", ", @allowed_types_array ) );
    # DEBUG( 'converted config as array = ' . join( ", ", @conv_allowed_types_array ) );

    # Create an array of types from the well allele determination
    my $curr_well_allele_types_string = $self->current_well->{ 'allele_determination' };
    my @curr_well_allele_types_array = split( /;\s/, $curr_well_allele_types_string );

    LIMS2::Exception->throw( 'Failed: No allele types for well so cannot determine genotyping pass' ) unless ( scalar @curr_well_allele_types_array > 0 );

    # DEBUG( 'alele_types string = ' . $curr_well_allele_types_string );
    # DEBUG( 'allele types as array = ' . join( ", ", @curr_well_allele_types_array ) );

    # Cycle through the allele determination types and check if any match against the allowed types
    # N.B. This is currently coded so that ANY one matching allele type triggers a pass
    my $valid = 0;
    foreach my $curr_well_allele_type ( @curr_well_allele_types_array ) {
        if ( $curr_well_allele_type ~~ @conv_allowed_types_array ) {
            # DEBUG ( $curr_well_allele_type . ' matches!' );
            $valid = 1;
        }
    }

    return $valid;
}

=head2 _apply_additional_genotyping_pass_criteria

Determine whether the well includes any additional tests for a genotyping pass and check them.
At least one genotyping_pass test must be defined in the config called 'pass', although it may have an empty logic string if no further tests are required

=cut
sub _apply_additional_genotyping_pass_criteria {
    my ( $self ) = @_;

    # may be more than one test to check
    my @passed_tests;
    my $tests = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'genotyping_pass' }->{ 'tests' };

    unless ( defined $tests ) { LIMS2::Exception->throw("apply additional genotyping tests: no tests defined in config") };

    foreach my $key ( keys %{ $tests } ) {

        # Get the specific logic for this particular workflow and scope into this method:
        my $logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ 'genotyping_pass' }->{ 'tests' }->{ $key };

        # if (defined $logic_string ) { print "well id " . $self->current_well_id . " pass criteria logic string = " . $logic_string . "\n"; }

        # check string is defined
        LIMS2::Exception->throw("apply additional genotyping pass criteria: no tests logic string defined for test " . $key ) unless ( defined $logic_string );

        # if logic string is empty then no further tests required and well has passed test
        if ( $logic_string eq '' ) {
            # print "well id " . $self->current_well_id . " logic string empty\n";
            push( @passed_tests, $key );
        }
        else {
            if ( $self->_is_allele_test( $logic_string ) ) {
                push( @passed_tests, $key );
            }
        }
    }

    if ( scalar @passed_tests > 0 ) {
        return join( '; ', ( sort @passed_tests ) );
    }
    else {
        return 'fail';
    }
}

=head2 _set_calculated_well_accepted_value

Set the displayed calculated genotyping pass depending on the current well accepted value.
Want visible indication when it differs from current database value.

=cut
sub _set_calculated_well_accepted_value {
    my ( $self, $genotyping_pass ) = @_;

    unless ( defined $genotyping_pass && defined $self->current_well->{ 'accepted' } ) { return; }

    # store an accepted value for each well, indicating where different than current database value
    if ( $genotyping_pass eq 'fail' || $genotyping_pass eq '' ) {
        if ( $self->current_well->{ 'accepted' } eq 'yes') {
            $self->current_well->{ 'accepted' } = '* no';
            $self->current_well->{ 'update_for_accepted' } = 0;
        }
    }
    else {
        if ( $self->current_well->{ 'accepted' } eq 'no') {
            $self->current_well->{ 'accepted' } = '* yes';
            $self->current_well->{ 'update_for_accepted' } = 1;
        }
    }

    return;
}

=head2 _is_loacrit_0

Retrieve thresholds and apply test for is LOA-crit zero.

=cut
sub _is_loacrit_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_loacrit_1

Retrieve thresholds and apply test for is LOA-crit one.

=cut
sub _is_loacrit_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_loacrit_2

Retrieve thresholds and apply test for is LOA-crit two.

=cut
sub _is_loacrit_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_loatam_0

Retrieve thresholds and apply test for is LOA-tam zero.

=cut
sub _is_loatam_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_loatam_1

Retrieve thresholds and apply test for is LOA-tam one.

=cut
sub _is_loatam_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_loatam_2

Retrieve thresholds and apply test for is LOA-tam two.

=cut
sub _is_loatam_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_loadel_0

Retrieve thresholds and apply test for is LOA-del zero.

=cut
sub _is_loadel_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_loadel_1

Retrieve thresholds and apply test for is LOA-del one.

=cut
sub _is_loadel_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_loadel_2

Retrieve thresholds and apply test for is LOA-del two.

=cut
sub _is_loadel_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_cre_0

Retrieve thresholds and apply test for is Cre zero.

=cut
sub _is_cre_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'cre_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'cre_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'cre' );
}

=head2 _is_cre_1

Retrieve thresholds and apply test for is Cre one.

=cut
sub _is_cre_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'cre_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'cre_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'cre' );
}

=head2 _is_chry_0

Retrieve thresholds and apply test for is Chry zero.

=cut
sub _is_chry_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_chry_1

Retrieve thresholds and apply test for is Chry one.

=cut
sub _is_chry_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_chry_2

Retrieve thresholds and apply test for is Chry two.

=cut
sub _is_chry_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_2_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_2_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_chr8a_0

Retrieve thresholds and apply test for is Chr8a zero.

=cut
sub _is_chr8a_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_0_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_0_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_chr8a_1

Retrieve thresholds and apply test for is Chr8a one.

=cut
sub _is_chr8a_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_1_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_1_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_chr8a_2

Retrieve thresholds and apply test for is Chr8a two.

=cut
sub _is_chr8a_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_2_lower_bound' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_2_upper_bound' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_potential_loacrit_0

Retrieve thresholds and apply test for is potential LOA-crit zero.

=cut
sub _is_potential_loacrit_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_potential_loacrit_1

Retrieve thresholds and apply test for is potential LOA-crit one.

=cut
sub _is_potential_loacrit_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_potential_loacrit_2

Retrieve thresholds and apply test for is potential LOA-crit two.

=cut
sub _is_potential_loacrit_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loacrit_2_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loacrit' );
}

=head2 _is_potential_loatam_0

Retrieve thresholds and apply test for is potential LOA-tam zero.

=cut
sub _is_potential_loatam_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_potential_loatam_1

Retrieve thresholds and apply test for is potential LOA-tam one.

=cut
sub _is_potential_loatam_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_potential_loatam_2

Retrieve thresholds and apply test for is potential LOA-tam two.

=cut
sub _is_potential_loatam_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loatam_2_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loatam' );
}

=head2 _is_potential_loadel_0

Retrieve thresholds and apply test for is potential LOA-del zero.

=cut
sub _is_potential_loadel_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_potential_loadel_1

Retrieve thresholds and apply test for is potential LOA-del one.

=cut
sub _is_potential_loadel_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_potential_loadel_2

Retrieve thresholds and apply test for is potential LOA-del two.

=cut
sub _is_potential_loadel_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'loadel_2_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'loadel' );
}

=head2 _is_potential_cre_0

Retrieve thresholds and apply test for is potential Cre zero.

=cut
sub _is_potential_cre_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'cre_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'cre_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'cre' );
}

=head2 _is_potential_cre_1

Retrieve thresholds and apply test for is potential Cre one.

=cut
sub _is_potential_cre_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'cre_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'cre_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'cre' );
}

=head2 _is_potential_chry_0

Retrieve thresholds and apply test for is potential Chry zero.

=cut
sub _is_potential_chry_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_potential_chry_1

Retrieve thresholds and apply test for is potential Chry one.

=cut
sub _is_potential_chry_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_potential_chry_2

Retrieve thresholds and apply test for is potential Chry two.

=cut
sub _is_potential_chry_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chry_2_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chry_2_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chry' );
}

=head2 _is_potential_chr8a_0

Retrieve thresholds and apply test for is potential Chr8a zero.

=cut
sub _is_potential_chr8a_0 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_0_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_0_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_potential_chr8a_1

Retrieve thresholds and apply test for is potential Chr8a one.

=cut
sub _is_potential_chr8a_1 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_1_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_1_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_potential_chr8a_2

Retrieve thresholds and apply test for is potential Chr8a two.

=cut
sub _is_potential_chr8a_2 {
    my ( $self ) = @_;

    my $lower = $self->allele_config->{ 'thresholds' }->{ 'chr8a_2_lower_bound_loose' };
    my $upper = $self->allele_config->{ 'thresholds' }->{ 'chr8a_2_upper_bound_loose' };

    unless ( defined $lower && defined $upper ) { return 0 };

    return $self->_is_assay_copy_number_in_rng( $lower, $upper, 'chr8a' );
}

=head2 _is_neo_present

Retrieve threshold and apply test for is Neo resistance present.

=cut
sub _is_neo_present {
    my ( $self ) = @_;

    my $neo_threshold = $self->allele_config->{ 'thresholds' }->{ 'neo_present_threshold' };

    return $self->_is_marker_present( $neo_threshold, 'neo' );
}

=head2 _is_bsd_present

Retrieve threshold and apply test for is Bsd resistance present.

=cut
sub _is_bsd_present {
    my ( $self ) = @_;

    my $bsd_threshold = $self->allele_config->{ 'thresholds' }->{ 'bsd_present_threshold' };

    return $self->_is_marker_present( $bsd_threshold, 'bsd' );
}

=head2 _is_puro_present

Retrieve threshold and apply test for is Puro resistance present.

=cut
sub _is_puro_present {
    my ( $self ) = @_;

    my $puro_threshold = $self->allele_config->{ 'thresholds' }->{ 'puro_present_threshold' };

    return $self->_is_marker_present( $puro_threshold, 'puro' );
}

=head2 _is_lrpcr_pass

Apply test for is LRPCR primer bands pass.

=cut
sub _is_lrpcr_pass {
    my ( $self ) = @_;

    my $gf3 = $self->current_well->{ 'gf3' };
    my $gr3 = $self->current_well->{ 'gr3' };
    my $gf4 = $self->current_well->{ 'gf4' };
    my $gr4 = $self->current_well->{ 'gr4' };

    # expecting 'pass' in all four fields
    unless ( defined $gf3 && $gf3 eq 'pass' ) { return 0; }
    unless ( defined $gr3 && $gr3 eq 'pass' ) { return 0; }
    unless ( defined $gf4 && $gf4 eq 'pass' ) { return 0; }
    unless ( defined $gr4 && $gr4 eq 'pass' ) { return 0; }

    return 1;
}

=head2 _is_assay_copy_number_in_rng

Generic method to check if assay copy number is within the allowed range.

=cut
sub _is_assay_copy_number_in_rng {
    my ( $self, $min, $max, $assay_name ) = @_;

    my $value = $self->current_well->{ $assay_name . '#copy_number' };

    if ( defined $value && $value ne '-' ) {
        return $self->_is_value_in_range( $min, $max, $value );
    }
    else {
        return 0;
    }
}

=head2 _is_marker_present

Generic method to check if resistance marker copy number is over the threshold.

=cut
sub _is_marker_present {
    my ( $self, $threshold, $marker ) = @_;

    my $value = $self->current_well->{ $marker . '#copy_number' };

    if ( ( defined $value ) && ( $value ne '-' ) && ( $value >= $threshold ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _is_value_in_range

Generic method to check if value is within the set range.

=cut
sub _is_value_in_range {
    my ( $self, $min, $max, $value ) = @_;

    if ( ( $value >= $min ) && ( $value <= $max ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 _validate_assays

Validate the assay logic strings from the allele config file according to the current well workflow, stage and constraint. 

=cut
sub _validate_assays {
    my ( $self, $constraint_name ) = @_;

    LIMS2::Exception->throw( "validate assays: no current well set" )          unless $self->current_well_id;
    LIMS2::Exception->throw( "validate assays: no current well workflow set" ) unless $self->current_well_workflow;
    LIMS2::Exception->throw( "validate assays: no current well stage set" )    unless $self->current_well_stage;

    # print 'curr well id = '. $self->current_well_id . ' validate assays: workflow = ' . $self->current_well_workflow . ' stage = ' . $self->current_well_stage . ' constraint name = ' . $constraint_name . "\n";

    # Get the specific logic for this particular workflow and scope into this method:
    my $validation_logic_string = $self->allele_config->{ $self->current_well_workflow }->{ $self->current_well_stage }->{ $constraint_name }->{ 'validation' }->{ 'assays' };

    unless ( defined $validation_logic_string ) { LIMS2::Exception->throw( "validation: no validation logic string defined" ); }

    # logic string looks like this: 'loacrit AND loatam AND neo'
    # Get the parser to read this, interpret logic and run correct validate assay methods
    my $parser = Parse::BooleanLogic->new();
    my $tree   = $parser->as_array( $validation_logic_string );

    my $callback = sub {
        my $self    = pop;
        my $operand = $_[0]->{ 'operand' };

        # print 'curr_well_id = ' . $self->current_well_id . ' val operand = ' . $operand . "\n";

        my $method  = $self->dispatches->{ $operand };
        return $method->();
    };

    my $result = $parser->solve( $tree, $callback, $self );

    return $result;
}

=head2 _validate_assays

Check the current well assay has a valid result or whether it should be disregarded.
Copy number range must be below a certain threshold (indicates variability of the assay result).
Vic number must be within a certain range (indicates DNA concentration which cannot be too high or low).

=cut
sub _validate_assay {
    my ( $self, $assay_name ) = @_;

    # print "validating assay : $assay_name\n";

    my $cn              = $self->current_well->{ $assay_name . '#copy_number' };
    my $cnr             = $self->current_well->{ $assay_name . '#copy_number_range' };
    my $vic             = $self->current_well->{ $assay_name . '#vic' };
    my $cnr_threshold   = $self->allele_config->{ 'thresholds' }->{ $assay_name . '_copy_number_range_threshold' };
    my $vic_lower_bound = $self->allele_config->{ 'thresholds' }->{ $assay_name . '_vic_number_lower_bound' };
    my $vic_upper_bound = $self->allele_config->{ 'thresholds' }->{ $assay_name . '_vic_number_upper_bound' };

    #TODO: add checks on confidence
    #my $conf = $self->current_well->{ $assay_name . '#confidence' };

    unless ( defined $cn && $cn ne '-' ) {

        # LIMS2::Exception->throw( "$assay_name assay validation: Copy Number not present' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Copy Number not present. ' );
        return 0;
    }

    unless ( defined $cnr && $cnr ne '-' ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Copy Number Range not present' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Copy Number Range not present. ' );
        return 0;
    }

    unless ( defined $cnr_threshold ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Copy Number Range threshold missing from config' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Copy Number Range threshold missing from config. ' );
        return 0;
    }

    unless ( $cnr <= $cnr_threshold ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Copy Number Range above threshold' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Copy Number Range above threshold. ' );
        return 0;
    }

    unless ( defined $vic_lower_bound && defined $vic_upper_bound ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Vic number boundary thresholds missing from config' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Vic number boundary thresholds missing from config. ' );
        return 0;
    }

    unless ( defined $vic && $vic ne '-' ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Vic number not present' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Vic number not present. ' );
        return 0;
    }

    unless ( $vic >= $vic_lower_bound ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Vic number low DNA concentration HIGH' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Vic number low so DNA concentration HIGH. ' );
        return 0;
    }

    unless ( $vic <= $vic_upper_bound ) {

        # LIMS2::Exception->throw( $assay_name.' assay validation: Vic number high so DNA concentration LOW ' );
        $self->current_well_validation_msg(
            $self->current_well_validation_msg . $assay_name.' assay validation: Vic number high so DNA concentration LOW. ' );
        return 0;
    }

    # TODO: add validation for confidence

    return 1;
}

=head2 _validate_primers

Validate the LRPCR primer assays. 

=cut
sub _validate_primers {
    my ( $self, $assay_name ) = @_;

    my $gf3 = $self->current_well->{ 'gf3' };
    my $gr3 = $self->current_well->{ 'gr3' };
    my $gf4 = $self->current_well->{ 'gf4' };
    my $gr4 = $self->current_well->{ 'gr4' };

    # expecting 'pass','fail' (or blank if not done)
    unless ( defined $gf3 && ( $gf3 ~~ [ qw( pass fail ) ] ) ) {
        $self->current_well_validation_msg( $self->current_well_validation_msg . "$assay_name assay validation: gf3 value not present. " );
        return 0;
    }

    unless ( defined $gr3 && ( $gr3 ~~ [ qw( pass fail ) ] ) ) {
        $self->current_well_validation_msg( $self->current_well_validation_msg . "$assay_name assay validation: gr3 value not present. " );
        return 0;
    }

    unless ( defined $gf4 && ( $gf4 ~~ [ qw( pass fail ) ] ) ) {
        $self->current_well_validation_msg( $self->current_well_validation_msg . "$assay_name assay validation: gf4 value not present. " );
        return 0;
    }

    unless ( defined $gr4 && ( $gr4 ~~ [ qw( pass fail ) ] ) ) {
        $self->current_well_validation_msg( $self->current_well_validation_msg . "$assay_name assay validation: gr4 value not present. " );
        return 0;
    }

    return 1;
}

=head2 _validate_assay_exists

Validate whether the assay has been done.

=cut
sub _validate_assay_exists {
    my ( $self, $assay_name ) = @_;

    my $cn              = $self->current_well->{ $assay_name . '#copy_number' };
    # TODO: is it enough to check just copy number?
    # my $cnr             = $self->current_well->{ $assay_name . '#copy_number_range' };
    # my $vic             = $self->current_well->{ $assay_name . '#vic' };

    # copy number is critical, so check if that exists
    unless ( defined $cn ) { return 0; }

    return 1;
}

=head2 _initialise_current_well_attributes

Initialise the current well attributes.

=cut
sub _initialise_current_well_attributes {
    my ( $self ) = @_;

    $self->current_well( undef );
    $self->current_well_id( undef );
    $self->current_well_stage( undef );
    $self->current_well_workflow( undef );
    $self->current_well_validation_msg ( undef );

    return;
}

=head2 _run_select_query

Generic method to run a select SQL query

=cut
sub _run_select_query {
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

=head2 _create_sql_select_summaries_fepd

Create the SQL query to select FINAL_PICK and EP details for an EPD well ID.

=cut
sub _create_sql_select_summaries_fepd {
    my ( $self, $well_ids ) = @_;

    $well_ids = join( ',', @{$well_ids} );

    my $sql_query = <<"SQL_END";
SELECT DISTINCT ep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, final_pick_cassette_cre, ep_well_recombinase_id
FROM summaries
WHERE ep_pick_well_id IN ( $well_ids )
SQL_END

    return $sql_query;
}

=head2 _create_sql_select_summaries_sepd

Create the SQL query to select FINAL_PICK and EP details for an SEPD well ID.

=cut
sub _create_sql_select_summaries_sepd {
    my ( $self, $well_ids ) = @_;

    $well_ids = join( ',', @{$well_ids} );

    my $sql_query = <<"SQL_END";
SELECT DISTINCT sep_pick_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, final_pick_cassette_cre, ep_well_recombinase_id
FROM summaries
WHERE sep_pick_well_id IN ( $well_ids )
and ep_pick_well_id > 0
SQL_END

    return $sql_query;
}

=head2 _create_sql_select_summaries_piq

Create the SQL query to select FINAL_PICK and EP details for a PIQ well ID.

=cut
sub _create_sql_select_summaries_piq {
    my ( $self, $well_ids ) = @_;

    $well_ids = join( ',', @{$well_ids} );

    my $sql_query = <<"SQL_END";
SELECT DISTINCT piq_well_id as well_id, final_pick_recombinase_id, final_pick_cassette_resistance, final_pick_cassette_cre, ep_well_recombinase_id
FROM summaries
WHERE piq_well_id IN ( $well_ids )
SQL_END

    return $sql_query;
}

=head2 _create_sql_select_qc_data

Create the SQL query to select genotyping results for a well ID.

=cut
sub _create_sql_select_qc_data {
    my ( $self, $well_id ) = @_;

    my $sql_query = <<"SQL_END";
SELECT well_id, genotyping_result_type_id
FROM well_genotyping_results
WHERE well_id = $well_id
SQL_END

    return $sql_query;
}

1;

__END__
