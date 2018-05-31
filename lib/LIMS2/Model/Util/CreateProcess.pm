package LIMS2::Model::Util::CreateProcess;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateProcess::VERSION = '0.504';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            process_fields
            process_plate_types
            process_aux_data_field_list
            link_process_wells
            create_process_aux_data
            create_process_aux_data_recombinase
          )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::MoreUtils qw( uniq notall none );
use LIMS2::Model::Util qw( well_id_for );
use LIMS2::Model::Util::Crisprs qw( get_crispr_group_by_crispr_ids );
use LIMS2::Exception::Implementation;
use LIMS2::Exception::Validation;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_INPUT_WELL_CHECK );
use TryCatch;

my %process_field_data = (
    final_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'final-cassette' ) },
        label  => 'Cassette (Final)',
        name   => 'cassette',
    },
    final_backbone => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('Backbone')->all ] },
        label  => 'Backbone (Final)',
        name   => 'backbone',
    },
    intermediate_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-cassette' ) },
        label  => 'Cassette (Intermediate)',
        name   => 'cassette',
    },
    intermediate_backbone => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-backbone' ) },
        label  => 'Backbone (Intermediate)',
        name   => 'backbone',
    },
    cell_line => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('CellLine')->all ] },
        label  => 'Cell Line',
        name   => 'cell_line',
    },
    recombinase => {
        values => sub{ return [ map{ $_->id } shift->schema->resultset('Recombinase')->all ] },
        label  => 'Recombinase',
        name   => 'recombinase',
    },
    nuclease => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('Nuclease')->all ]},
        label  => 'Nuclease',
        name   => 'nuclease',
    },
    backbone => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('Backbone')->all ] },
        label  => 'Backbone',
        name   => 'backbone',
    },
    crispr_tracker_rna => {
        values => sub{ return [ map{ $_->name } shift->schema->resultset('CrisprTrackerRna')->all ] },
        label  => 'Tracker RNA',
        name   => 'crispr_tracker_rna',
    },
);

sub process_fields {
    my ( $model, $process_type ) = @_;
    my %process_fields;
    my $fields = exists $PROCESS_SPECIFIC_FIELDS{$process_type} ? $PROCESS_SPECIFIC_FIELDS{$process_type} : [];

    for my $field ( @{ $fields } ) {
        LIMS2::Exception::Implementation->throw(
            "Don't know how to setup process field $field"
        ) unless exists $process_field_data{$field};

        my $field_values = $process_field_data{$field}{values}->($model);
        $process_fields{$field} = {
            values => $field_values,
            label  => $process_field_data{$field}{label},
            name   => $process_field_data{$field}{name},
        };
    }

    return \%process_fields;
}

sub _eng_seq_type_list {
    my ( $model, $type ) = @_;

    my $eng_seqs = $model->eng_seq_builder->list_seqs( type => $type );

    return [ map{ $_->{name} } @{ $eng_seqs } ];
}

sub process_plate_types {
    my ( $model, $process_type ) = @_;
    my $plate_types;

    if ( exists $PROCESS_PLATE_TYPES{$process_type} ) {
        $plate_types = $PROCESS_PLATE_TYPES{$process_type};
    }
    else {
        $plate_types = [ map{ $_->id } @{ $model->list_plate_types } ];
    }

    return $plate_types;
}

sub process_aux_data_field_list {
    return [ uniq map{ $process_field_data{$_}{name} } keys %process_field_data ];
}

sub link_process_wells {
    my ( $model, $process, $params ) = @_;

    for my $input_well ( @{ $params->{input_wells} || [] } ) {
        $process->create_related(
            process_input_wells => { well_id => well_id_for( $model, $input_well) } );
    }

    for my $output_well ( @{ $params->{output_wells} || [] } ) {
        $process->create_related(
            process_output_wells => { well_id => well_id_for( $model, $output_well) } );
    }

    check_process_wells( $model, $process, $params );

    return;
}

# Well validation for each process type
my %process_check_well = (
    'create_di'              => \&_check_wells_create_di,
    'create_crispr'          => \&_check_wells_create_crispr,
    'int_recom'              => \&_check_wells_int_recom,
    'global_arm_shortening'  => \&_check_wells_global_arm_shortening,
    '2w_gateway'             => \&_check_wells_2w_gateway,
    '3w_gateway'             => \&_check_wells_3w_gateway,
    'legacy_gateway'         => \&_check_wells_legacy_gateway,
    'final_pick'             => \&_check_wells_final_pick,
    'recombinase'            => \&_check_wells_recombinase,
    'cre_bac_recom'          => \&_check_wells_cre_bac_recom,
    'rearray'                => \&_check_wells_rearray,
    'dna_prep'               => \&_check_wells_dna_prep,
    'clone_pick'             => \&_check_wells_clone_pick,
    'clone_pool'             => \&_check_wells_clone_pool,
    'first_electroporation'  => \&_check_wells_first_electroporation,
    'second_electroporation' => \&_check_wells_second_electroporation,
    'freeze'                 => \&_check_wells_freeze,
    'xep_pool'               => \&_check_wells_xep_pool,
    'dist_qc'                => \&_check_wells_dist_qc,
    'crispr_vector'          => \&_check_wells_crispr_vector,
    'single_crispr_assembly' => \&_check_wells_single_crispr_assembly,
    'paired_crispr_assembly' => \&_check_wells_paired_crispr_assembly,
    'group_crispr_assembly'  => \&_check_wells_group_crispr_assembly,
    'crispr_ep'              => \&_check_wells_crispr_ep,
    'crispr_sep'             => \&_check_wells_crispr_sep,
    'oligo_assembly'         => \&_check_wells_oligo_assembly,
    'cgap_qc'                => \&_check_wells_cgap_qc,
    'ms_qc'                  => \&_check_wells_ms_qc,
    'doubling'               => \&_check_wells_doubling,
    'vector_cloning'         => \&_check_wells_vector_cloning,
    'golden_gate'            => \&_check_wells_golden_gate,
    'miseq_no_template'      => \&_check_wells_miseq_no_template,
    'miseq_oligo'            => \&_check_wells_miseq_oligo,
    'miseq_vector'           => \&_check_wells_miseq_vector,
    'ep_pipeline_ii'         => \&_check_wells_ep_pipeline_ii,
);

sub check_process_wells {
    my ( $model, $process, $params ) = @_;

    my $process_type = $params->{type};
    LIMS2::Exception::Implementation->throw(
        "Don't know how to validate wells for process type $process_type"
    ) unless exists $process_check_well{ $process_type };

    $process_check_well{ $process_type }->( $model, $process );

    return;
}

sub check_input_wells {
    my ( $model, $process ) = @_;

    my $process_type = $process->type_id;

    my @input_wells               = $process->input_wells;
    my $count                     = scalar @input_wells;
    my $expected_input_well_count = $PROCESS_INPUT_WELL_CHECK{$process_type}{number};
    LIMS2::Exception::Validation->throw(
            "$process_type process should have $expected_input_well_count input well(s) (got $count)"
    ) unless ($count eq $expected_input_well_count)
        || ($count > 0 and $expected_input_well_count eq 'MULTIPLE');

    return unless exists $PROCESS_INPUT_WELL_CHECK{$process_type}{type};

    my @types = uniq map { $_->plate_type } @input_wells;
    my %expected_input_process_types
        = map { $_ => 1 } @{ $PROCESS_INPUT_WELL_CHECK{$process_type}{type} };

    LIMS2::Exception::Validation->throw(
        "$process_type process input well should be type "
        . join( ',', keys %expected_input_process_types )
        . ' (got '
        . join( ',', @types )
        . ')'
    ) if notall { exists $expected_input_process_types{$_} } @types;

    return;
}

sub check_output_wells {
    my ( $model, $process ) = @_;

    my $process_type = $process->type_id;

    my @output_wells = $process->output_wells;
    my $count        = scalar @output_wells;
    # Only expect one output well per process, but schema can handle multiple
    LIMS2::Exception::Validation->throw(
        "Process should have 1 output well (got $count)"
    ) unless $count == 1;

    return unless exists $PROCESS_PLATE_TYPES{$process_type};

    my @types = uniq map { $_->plate_type } @output_wells;
    my %expected_output_process_types
        = map { $_ => 1 } @{ $PROCESS_PLATE_TYPES{$process_type} };

    LIMS2::Exception::Validation->throw(
        "$process_type process output well should be type "
        . join( ',', keys %expected_output_process_types )
        . ' (got '
        . join( ',', @types )
        . ')'
    ) if notall { exists $expected_output_process_types{$_} } @types;

    return;
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_create_di {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_create_crispr {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_int_recom {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_vector_cloning {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_global_arm_shortening {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_2w_gateway {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_3w_gateway {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_legacy_gateway {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_golden_gate {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_miseq_no_template {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_miseq_oligo {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_miseq_vector {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_final_pick {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_recombinase {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_cre_bac_recom {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

sub _check_wells_ep_pipeline_ii {
    my ( $model, $process ) = @_;

    check_output_wells( $model, $process);
    return;
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_rearray {
    my ( $model, $process ) = @_;

    # XXX Does not allow for pooled rearray
    check_input_wells( $model, $process);

    my @input_wells = $process->input_wells;

    # Output well type must be the same as the input well type
    my $in_type = $input_wells[0]->plate_type;
    my @output_types = uniq map { $_->plate_type } $process->output_wells;

    my @invalid_types = grep { $_ ne $in_type } @output_types;

    if ( @invalid_types > 0 ) {
        my $mesg
            = sprintf
            'rearray process should have input and output wells of the same type (expected %s, got %s)',
            $in_type, join( q/,/, @invalid_types );
        LIMS2::Exception::Validation->throw( $mesg );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_dna_prep {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_clone_pick {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    my ($input_well) = $process->input_wells;
    my ($output_well) = $process->output_wells;
    if($input_well->plate_type eq 'CRISPR_SEP'){
        if($output_well->plate_type ne 'SEP_PICK'){
            my $msg = 'clone_pick process with CRISPR_SEP input well must produce SEP_PICK output well, not '
                      .$output_well->plate_type;
            LIMS2::Exception::Validation->throw($msg);
        }
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_clone_pool {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_first_electroporation {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_second_electroporation {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    #two input wells, one must be xep, other dna
    my @input_well_types = map{ $_->plate_type } $process->input_wells;

    if ( ( none { $_ eq 'XEP' } @input_well_types ) || ( none { $_ eq 'DNA' } @input_well_types ) ) {
        LIMS2::Exception::Validation->throw(
            'second_electroporation process types require two input wells, one of type XEP '
            . 'and the other of type DNA'
            . ' (got ' . join( ',', @input_well_types ) . ')'
        );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_freeze {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    my ($input_well) = $process->input_wells;
    my ($output_well) = $process->output_wells;
    if($input_well->plate_type eq 'SEP_PICK'){
        if($output_well->plate_type ne 'SFP'){
            my $msg = 'freeze process with SEP_PICK input well must produce SFP output well, not '
                      .$output_well->plate_type;
            LIMS2::Exception::Validation->throw($msg);
        }
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
# NOTE if global_arm_shortening process used in a wells ancestors the design ids
#      will be of the root design well, not the global shortened arm design
#      Currently this process only used for single targetted cells so should not turn
#      up in the xep well. If this changes modify the method below to the $well->design
#      which will return the correct shortedn arm design for a well
sub _check_wells_xep_pool {
    my ( $model, $process ) = @_;
    check_input_wells( $model, $process);
    # Implement rules to validate the input wells.
    # The wells must all be for the same design.
    my @input_well_ids = map{ $_->id } $process->input_wells;

    my $design_data = $model->get_design_data_for_well_id_list( \@input_well_ids );
    # Now check that the design IDs are all the same
    my %design_ids;
    foreach my $input_well_id ( @input_well_ids ) {
        $design_ids{$design_data->{$input_well_id}->{'design_id'}} += 1;
    }

    if ((scalar keys %design_ids) > 1 ) {
        my $message;
        for my $candidate_well ( @input_well_ids ) {
            $message .= 'Well id: '
                . $candidate_well
                . ' design_id: '
                . $design_data->{$candidate_well}->{'design_id'}
                . "\n";
        }
        LIMS2::Exception::Validation->throw(
            'Candidate wells for xep_pool operation do not all descend from the same design'
            . "\n"
            . $message
        );
    }

    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_dist_qc {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);

    # input wells cannot be used to create PIQ wells more than once
    my @input_well_ids = map{ $_->id } $process->input_wells;

    # for each input FP well check that it does not already exist as a dist_qc well
    my @input_wells = $process->input_wells;
    foreach my $input_well (@input_wells) {
        my @child_processes = $input_well->child_processes;

        my @dist_processes;
        foreach my $child_process (@child_processes) {
            if ( $child_process->type_id eq 'dist_qc' ) {

                push @dist_processes, $child_process;
            }
        }
        my $dist_count      = scalar @dist_processes;

        # check for more than one as new wells already exist at this point (albeit inside transaction)
        # if ($dist_count > 1) {
        #     my $well_string = $input_well->as_string;

        #     my @piq_wells;
        #     foreach my $dist_process ( @dist_processes ) {
        #         push @piq_wells, $dist_process->output_wells->first->as_string;
        #     }

        #     my $piq_wells_string = join( ' and ', @piq_wells );

        #     LIMS2::Exception::Validation->throw(
        #       'FP well ' . $well_string . ' would be linked to PIQ wells ' . $piq_wells_string .
        #       '; one FP well cannot be used to make more than one PIQ well' . "\n"
        #     );
        # }
    }

    my ($input_well) = $process->input_wells;
    my ($output_well) = $process->output_wells;
    if($input_well->plate_type eq 'SFP'){
        if($output_well->plate_type ne 'S_PIQ'){
            my $msg = 'dist_qc process with SFP input well must produce S_PIQ output well, not '
                      .$output_well->plate_type;
            LIMS2::Exception::Validation->throw($msg);
        }
    }

    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_crispr_vector {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_single_crispr_assembly {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    # 2 DNA input wells, 1 must be from CRISPR_V, 1 from FINAL_PICK
    my @input_wells = $process->input_wells;
    my @input_parent_wells = map { $_->ancestors->input_wells($_) } @input_wells;

    my $crispr_v = 0;
    my $final_pick = 0;

    foreach (@input_parent_wells) {
        if ($_->plate_type eq 'CRISPR_V') {
            $crispr_v++;
            unless (defined $_->crispr) {
            LIMS2::Exception::Validation->throw(
                "Well $_ is not a crispr." );
            }

        }
        if ($_->plate_type eq 'FINAL_PICK') {$final_pick++}
    }
    unless ($crispr_v == 1 && $final_pick == 1 ) {
        LIMS2::Exception::Validation->throw(
            'single_crispr_assembly requires two input wells, one DNA prepared from a CRISPR_V '
            . 'and one DNA prepared from a FINAL_PICK '
        );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_paired_crispr_assembly {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    # 3 DNA input wells, 2 must be from CRISPR_V, 1 from FINAL_PICK
    my @input_wells = $process->input_wells;
    my @input_parent_wells = map { $_->ancestors->input_wells($_) } @input_wells;

    my $crispr_v = 0;
    my $final_pick = 0;
    my $pamright;
    my $pamleft;

    foreach (@input_parent_wells) {
        if ($_->plate_type eq 'CRISPR_V') {
            $crispr_v++;
            my $crispr = $_->crispr; # single crispr
            unless (defined $crispr) {
            LIMS2::Exception::Validation->throw(
                "Well $_ is not a crispr." );
            }
            unless ( defined $crispr->pam_right) {
            LIMS2::Exception::Validation->throw(
                'Crispr '. $crispr->id . ' does not have direction' );
            }
            if ($crispr->pam_right) {
                $pamright = 1;
            } else {
                $pamleft = 1;
            }
        }
        if ($_->plate_type eq 'FINAL_PICK') {$final_pick++}
    }

    unless ($crispr_v == 2 && $final_pick == 1 ) {
        LIMS2::Exception::Validation->throw(
            'paired_crispr_assembly requires three input wells, two DNAs prepared from a CRISPR_V '
            . 'and one DNA prepared from a FINAL_PICK'
        );
    }
    unless ($pamright && $pamleft ) {
        LIMS2::Exception::Validation->throw(
            'paired_crispr_assembly requires DNA prepared from paired CRISPR_V wells. '
            . 'The provided pair is not valid'
        );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
## no critic(Subroutines::RequireFinalReturn)
sub _check_wells_group_crispr_assembly {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    my ($new_well) = $process->process_output_wells;
    my $new_well_name = $new_well->well->name;

    # multiple DNA input wells, some must be from CRISPR_V, 1 from FINAL_PICK
    my @input_wells = $process->input_wells;
    my @input_parent_wells = map { $_->ancestors->input_wells($_) } @input_wells;

    my $crispr_v = 0;
    my $final_pick = 0;
    my @crispr_ids;

    foreach (@input_parent_wells) {
        if ($_->plate_type eq 'CRISPR_V') {
            $crispr_v++;
            my $crispr = $_->crispr; # single crispr
            unless (defined $crispr) {
            LIMS2::Exception::Validation->throw(
                "Well $_ is not a crispr." );
            }
            push @crispr_ids, $crispr;
        }
        if ($_->plate_type eq 'FINAL_PICK') {$final_pick++}
    }

    @crispr_ids = uniq @crispr_ids;

    unless ($crispr_v > 0 && $final_pick == 1 ) {
        LIMS2::Exception::Validation->throw(
            'group_crispr_assembly requires as input at least 1 DNA prepared from a CRISPR_V '
            . 'and 1 DNA prepared from a FINAL_PICK'
        );
    }

    try{
        my $group = get_crispr_group_by_crispr_ids( $model->schema, { crispr_ids => \@crispr_ids } );
    }
    catch ($err) {
        my $ids_list = join ", ",@crispr_ids;
        LIMS2::Exception::Validation->throw("Could not create well $new_well_name: $err");
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_crispr_ep {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_crispr_sep {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    #two input wells, one must be PIQ, other ASSEMBLY
    my @input_well_types = map{ $_->plate_type } $process->input_wells;

    if ( ( none { $_ eq 'PIQ' } @input_well_types ) || ( none { $_ eq 'ASSEMBLY' } @input_well_types ) ) {
        LIMS2::Exception::Validation->throw(
            'crispr_sep (second electroporation) processes require two input wells, one of type PIQ '
            . 'and the other of type ASSEMBLY'
            . ' (got ' . join( ',', @input_well_types ) . ')'
        );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_oligo_assembly {
    my ( $model, $process ) = @_;

    # One DESIGN input well, one CRISPR input well
    check_input_wells( $model, $process);
    check_output_wells( $model, $process);

    my ( $design, $crispr );
    foreach ( $process->input_wells ) {
        if ($_->plate_type eq 'DESIGN') {
            $design = $_->design;
        }
        elsif ($_->plate_type eq 'CRISPR') {
            $crispr = $_->crispr;
        }
    }

    if ( $design->design_type_id eq 'nonsense' ) {
        # check nonsense design and crispr match up
        unless ( $design->nonsense_design_crispr_id == $crispr->id ) {
            LIMS2::Exception::Validation->throw( 'nonsense design is linked to crispr '
                    . $design->nonsense_design_crispr_id
                    . ', not crispr ' . $crispr->id );
        }
    }
    else {
        LIMS2::Exception::Validation->throw(
            'oligo_assembly can only use nonsense type designs, not: ' . $design->design_type_id );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_cgap_qc {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_ms_qc {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process);
    check_output_wells( $model, $process);
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _check_wells_doubling {
    my ( $model, $process ) = @_;

    check_input_wells( $model, $process );

    # process can be created initially with no output wells
    # as it takes weeks to complete
    my @output_wells = $process->output_wells;
    if(scalar @output_wells){
        check_output_wells( $model, $process);
    }

    return;
}
## use critic

my %process_aux_data = (
    'create_di'              => \&_create_process_aux_data_create_di,
    'create_crispr'          => \&_create_process_aux_data_create_crispr,
    'int_recom'              => \&_create_process_aux_data_int_recom,
    'global_arm_shortening'  => \&_create_process_aux_global_arm_shortening,
    '2w_gateway'             => \&_create_process_aux_data_2w_gateway,
    '3w_gateway'             => \&_create_process_aux_data_3w_gateway,
    'legacy_gateway'         => \&_create_process_aux_data_legacy_gateway,
    'final_pick'             => \&_create_process_aux_data_final_pick,
    'recombinase'            => \&create_process_aux_data_recombinase,
    'cre_bac_recom'          => \&_create_process_aux_data_cre_bac_recom,
    'rearray'                => \&_create_process_aux_data_rearray,
    'dna_prep'               => \&_create_process_aux_data_dna_prep,
    'clone_pick'             => \&_create_process_aux_data_clone_pick,
    'clone_pool'             => \&_create_process_aux_data_clone_pool,
    'first_electroporation'  => \&_create_process_aux_data_first_electroporation,
    'second_electroporation' => \&_create_process_aux_data_second_electroporation,
    'freeze'                 => \&_create_process_aux_data_freeze,
    'xep_pool'               => \&_create_process_aux_data_xep_pool,
    'dist_qc'                => \&_create_process_aux_data_dist_qc,
    'crispr_vector'          => \&_create_process_aux_data_crispr_vector,
    'single_crispr_assembly' => \&_create_process_aux_data_single_crispr_assembly,
    'paired_crispr_assembly' => \&_create_process_aux_data_paired_crispr_assembly,
    'group_crispr_assembly'  => \&_create_process_aux_data_group_crispr_assembly,
    'crispr_ep'              => \&_create_process_aux_data_crispr_ep,
    'crispr_sep'             => \&_create_process_aux_data_crispr_sep,
    'oligo_assembly'         => \&_create_process_aux_data_oligo_assembly,
    'cgap_qc'                => \&_create_process_aux_data_cgap_qc,
    'ms_qc'                  => \&_create_process_aux_data_ms_qc,
    'doubling'               => \&_create_process_aux_data_doubling,
    'vector_cloning'         => \&_create_process_aux_data_vector_cloning,
    'golden_gate'            => \&_create_process_aux_data_golden_gate,
    'miseq_no_template'      => \&_create_process_aux_data_miseq_no_template,
    'miseq_oligo'            => \&_create_process_aux_data_miseq_oligo,
    'miseq_vector'           => \&_create_process_aux_data_miseq_vector,
    'ep_pipeline_ii'         => \&_create_process_aux_data_ep_pipeline_ii,
);

sub create_process_aux_data {
    my ( $model, $process, $params ) = @_;
    my $process_type = $process->type_id;
    LIMS2::Exception::Implementation->throw(
        "Don't know how to create auxiliary data for process type $process_type"
    ) unless exists $process_aux_data{ $process_type };

    $process_aux_data{ $process_type }->( $model, $params, $process );

    return;
}

sub pspec__create_process_aux_data_create_di {
    return {
        design_id => { validate => 'existing_design_id' },
        dna_template => { optional => 1 },
        bacs =>
            { validate => 'hashref', optional => 1 } # validate called on each element of bacs array
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_create_di {
    my ( $model, $params, $process ) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_create_di() );

    $process->create_related( process_design => { design_id => $validated_params->{design_id} } );

    for my $bac_params ( @{ $validated_params->{bacs} || [] } ) {
        my $validated_bac_params = $model->check_params(
            $bac_params,
            {   bac_plate   => { validate => 'bac_plate' },
                bac_library => { validate => 'bac_library' },
                bac_name    => { validate => 'bac_name' }
            }
        );
        my $bac_clone = $model->retrieve(
            BacClone => {
                name           => $validated_bac_params->{bac_name},
                bac_library_id => $validated_bac_params->{bac_library}
            }
        );

        $process->create_related(
            process_bacs => {
                bac_plate    => $validated_bac_params->{bac_plate},
                bac_clone_id => $bac_clone->id
            }
        );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_ep_pipeline_ii {
    return {
        design_id => { validate => 'existing_design_id' },
        crispr_id => { validate => 'existing_crispr_id', optional => 1 },
        cell_line => { validate => 'existing_cell_line_id' },
        nuclease     => { validate => 'existing_nuclease_name' },
        guided_type     => { validate => 'existing_guided_type_name' }
    };
}

sub _create_process_aux_data_ep_pipeline_ii {
    my ( $model, $params, $process ) = @_;

    my $validated_params = $model->check_params( $params, pspec__create_process_aux_data_ep_pipeline_ii() );

    $process->create_related( process_design => { design_id => $validated_params->{design_id} } );
    $process->create_related( process_crispr => { crispr_id => $validated_params->{crispr_id} } );
    $process->create_related( process_cell_line => { cell_line_id => $params->{cell_line} } );
    $process->create_related( process_nuclease => { nuclease_id => _nuclease_id_for( $model, $validated_params->{nuclease} ) } );
    $process->create_related( process_guided_type => { guided_type_id => _guided_type_id_for( $model, $validated_params->{guided_type} ) } );

    return;
}

sub pspec__create_process_aux_data_create_crispr {
    return {
        crispr_id => { validate => 'existing_crispr_id' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_create_crispr {
    my ( $model, $params, $process ) = @_;

    my $validated_params;

    $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_create_crispr() );

    $process->create_related( process_crispr => { crispr_id => $validated_params->{crispr_id} } );

    return;
}
## use critic

sub pspec__create_process_aux_data_int_recom {
    ## Backbone constraint must be set depending on species
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        dna_template => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_int_recom {
    my ( $model, $params, $process ) = @_;
    my $pspec = pspec__create_process_aux_data_int_recom;
    my ($input_well) = $process->process_input_wells;
    my $species_id = $input_well->well->plate_species->id;

    # allow any type of backbone for int_recom process now...
    # backbone puc19_RV_GIBSON is used in both int and final wells
    # and our final / intermediate backbone system does not handle this
    # case yet so for now allow anything
    $pspec->{backbone} = { validate => 'existing_backbone' };

    my $validated_params = $model->check_params( $params, $pspec );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_vector_cloning {
    ## Backbone constraint must be set depending on species
    return {
        dna_template => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_vector_cloning {
    my ( $model, $params, $process ) = @_;
    my $pspec = pspec__create_process_aux_data_vector_cloning;
    my ($input_well) = $process->process_input_wells;
    my $species_id = $input_well->well->plate_species->id;

    # allow any type of backbone for int_recom process now...
    # backbone puc19_RV_GIBSON is used in both int and final wells
    # and our final / intermediate backbone system does not handle this
    # case yet so for now allow anything
    $pspec->{backbone} = { validate => 'existing_backbone' };

    my $validated_params = $model->check_params( $params, $pspec );

    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_global_arm_shortening {
    return {
        backbone  => { validate => 'existing_intermediate_backbone' },
        design_id => { validate => 'existing_design_id' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_global_arm_shortening {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_global_arm_shortening );

    my $backbone = $model->schema->resultset('Backbone')->find( { name => $validated_params->{backbone} } );
    if ( $backbone->antibiotic_res !~ /chloramphenicol/i ) {
        LIMS2::Exception::Validation->throw(
            "The antibiotic resistance on the intermediate backbone used in a "
            . "global_arm_shortening process should be Chloramphenicol, not: "
            . $backbone->antibiotic_res
        );
    }

    # check specified design has a global_arm_shortened value and
    # that design_id is the same as the root design of the input well
    my $input_well = ( $process->input_wells )[0]; # we already checked there is only one input well
    my $root_design_id = $input_well->design->id;
    my $design = $model->c_retrieve_design( { id => $validated_params->{design_id} } );

    LIMS2::Exception::Validation->throw(
        "The specified design $design is not set as a short arm design"
    ) unless $design->global_arm_shortened;

    if ( $root_design_id != $design->global_arm_shortened ) {
        LIMS2::Exception::Validation->throw(
            "The short arm design $design "
            . "is not linked to the intermediate wells original design $root_design_id"
        );
    }

    $process->create_related(
        process_global_arm_shortening_design => { design_id => $validated_params->{design_id} } );
    $process->create_related( process_backbone =>
            { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_2w_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette', optional => 1 },
        backbone    => { validate => 'existing_backbone', optional => 1 },
        recombinase => { optional => 1 },
        REQUIRE_SOME => { cassette_or_backbone => [ 1, qw( cassette backbone ) ], },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_2w_gateway {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_2w_gateway );

    if ( $validated_params->{cassette} && $validated_params->{backbone} ) {
        LIMS2::Exception::Validation->throw(
            '2w_gateway process can have either a cassette or backbone, not both' );
    }

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } )
        if $validated_params->{cassette};
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } )
        if $validated_params->{backbone};

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_3w_gateway {
    return {
        cassette    => { validate => 'existing_cassette' },
        backbone    => { validate => 'existing_backbone' },
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_3w_gateway {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_3w_gateway );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_legacy_gateway {
    return {
        cassette    => { validate => 'existing_final_cassette', optional => 1 },
        backbone    => { validate => 'existing_backbone', optional => 1 },
        recombinase => { optional => 1 },
        REQUIRE_SOME => { cassette_or_backbone => [ 1, qw( cassette backbone ) ], },
    };
}

sub pspec__create_process_aux_data_golden_gate {
    return {
        cassette    => { validate => 'existing_final_cassette' },
        backbone    => { validate => 'existing_backbone' },
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_golden_gate {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_golden_gate );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
# legacy_gateway is like a gateway process but goes from INT to FINAL_PICK
# also it can have eith cassette or backbone, or both
sub _create_process_aux_data_legacy_gateway {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_legacy_gateway );

    $process->create_related( process_cassette =>
            { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } )
        if $validated_params->{cassette};
    $process->create_related( process_backbone =>
            { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } )
        if $validated_params->{backbone};

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase( $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

sub pspec_create_process_aux_data_recombinase {
    return { recombinase => { validate => 'existing_recombinase' }, };
}

#NOTE order recombinase added is just the order that they are specified in the array
## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub create_process_aux_data_recombinase {
    my ( $model, $params, $process ) = @_;
    my $validated_params
        = $model->check_params( $params, pspec_create_process_aux_data_recombinase, , ignore_unknown => 1 );

    LIMS2::Exception::Validation->throw(
        "recombinase process should have 1 or more recombinases"
    ) unless @{ $validated_params->{recombinase} };

    my $rank = ( $process->process_recombinases->get_column('rank')->max || 0 ) + 1;
    foreach my $recombinase ( @{ $validated_params->{recombinase} } ) {

        if ($process->process_recombinases->find( { 'recombinase_id' => $recombinase } )){
            LIMS2::Exception::Validation->throw("recombinase process already exists")
        }
        $process->create_related(
            process_recombinases => {
                recombinase_id => $recombinase,
                rank           => $rank++,
            }
        );
    }

    return;
}
## use critic

sub pspec__create_process_aux_data_cre_bac_recom {
    return {
        cassette => { validate => 'existing_intermediate_cassette' },
        backbone => { validate => 'existing_intermediate_backbone' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_cre_bac_recom {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_cre_bac_recom );

    $process->create_related( process_cassette => { cassette_id => _cassette_id_for( $model, $validated_params->{cassette} ) } );
    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_first_electroporation {
    return {
        cell_line => { validate => 'existing_cell_line' },
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_first_electroporation {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_first_electroporation, , ignore_unknown => 1 );

    $process->create_related( process_cell_line => { cell_line_id => _cell_line_id_for( $model, $validated_params->{cell_line} ) } );
    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_final_pick {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub pspec__create_process_aux_data_second_electroporation {
    return {
        recombinase => { optional => 1 },
    };
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_second_electroporation {
    my ( $model, $params, $process  ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_second_electroporation, , ignore_unknown => 1 );

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_miseq_no_template {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_miseq_oligo {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_miseq_vector {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_rearray {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_dna_prep {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_clone_pool {
    return;
}
## use critic

sub pspec__create_process_aux_data_clone_pick {
    return {
        recombinase => { optional => 1 },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_clone_pick {
    my ( $model, $params, $process  ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_clone_pick );

    if ( $validated_params->{recombinase} ) {
        create_process_aux_data_recombinase(
            $model,
            { recombinase => $validated_params->{recombinase} }, $process );
    }
    return ;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_freeze {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_xep_pool {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_dist_qc {
    return;
}
## use critic

sub pspec__create_process_aux_data_crispr_vector {
    return {
        backbone    => { validate => 'existing_backbone' },
    };
}


## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_crispr_vector {
    my ( $model, $params, $process ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_crispr_vector );

    $process->create_related( process_backbone => { backbone_id => _backbone_id_for( $model, $validated_params->{backbone} ) } );

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_single_crispr_assembly {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_paired_crispr_assembly {
    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_group_crispr_assembly {
    return;
}
## use critic

sub pspec__create_process_aux_data_crispr_ep {
    return {
        cell_line    => { validate => 'existing_cell_line' },
        nuclease     => { validate => 'existing_nuclease' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_crispr_ep {
    my ($model, $params, $process) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_crispr_ep );

    $process->create_related( process_cell_line => { cell_line_id => _cell_line_id_for( $model, $validated_params->{cell_line} ) }  );
    $process->create_related( process_nuclease => { nuclease_id => _nuclease_id_for( $model, $validated_params->{nuclease} ) } );

    return;
}
## use critic

sub pspec__create_process_aux_data_crispr_sep {
    return {
        nuclease     => { validate => 'existing_nuclease' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_crispr_sep {
    my ($model, $params, $process) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_crispr_sep, ignore_unknown => 1 );

    $process->create_related(
        process_nuclease => {
            nuclease_id => _nuclease_id_for( $model, $validated_params->{nuclease} )
        }
    );

    return;
}
## use critic

sub pspec__create_process_aux_data_oligo_assembly {
    return {
        crispr_tracker_rna => { validate => 'existing_crispr_tracker_rna' },
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_oligo_assembly {
    my ($model, $params, $process) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_oligo_assembly, ignore_unknown => 1 );

    $process->create_related( process_crispr_tracker_rna => { crispr_tracker_rna_id => _crispr_tracker_rna_id_for( $model, $validated_params->{crispr_tracker_rna} ) } );

    return;
}
## use critic

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_cgap_qc {
    return;
}
## use critic

sub pspec__create_process_aux_data_ms_qc{
    return {
        oxygen_condition => { validate => 'oxygen_condition' },
        doublings        => { validate => 'integer' }
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_ms_qc {
    my ($model, $params, $process) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_ms_qc, ignore_unknown => 1 );
    $process->create_related( process_parameters => {
        parameter_name  => 'oxygen_condition',
        parameter_value => $validated_params->{oxygen_condition}
    });

    $process->create_related( process_parameters => {
            parameter_name  => 'doublings',
            parameter_value => $validated_params->{doublings},
    });
    return;
}
## use critic

sub pspec__create_process_aux_data_doubling {
    return {
        oxygen_condition => { validate => 'oxygen_condition' },
        doublings        => { validate => 'integer', optional => 1 }
    };
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutine)
sub _create_process_aux_data_doubling {
    my ($model, $params, $process) = @_;
    my $validated_params
        = $model->check_params( $params, pspec__create_process_aux_data_doubling, ignore_unknown => 1 );
    $process->create_related( process_parameters => {
        parameter_name  => 'oxygen_condition',
        parameter_value => $validated_params->{oxygen_condition}
    });

    if(defined(my $doublings = $validated_params->{doublings})){
        $process->create_related( process_parameters => {
            parameter_name  => 'doublings',
            parameter_value => $doublings,
        });
    }
    return;
}
## use critic

sub _cassette_id_for {
    my ( $model, $cassette_name ) = @_;

    my $cassette = $model->retrieve( Cassette => { name => $cassette_name } );
    return $cassette->id;
}

sub _backbone_id_for {
    my ( $model, $backbone_name ) = @_;

    my $backbone = $model->retrieve( Backbone => { name => $backbone_name } );
    return $backbone->id;
}

sub _cell_line_id_for {
	my ( $model, $cell_line_name ) = @_;

	my $cell_line = $model->retrieve( CellLine => { name => $cell_line_name });
	return $cell_line->id;
}

sub _nuclease_id_for{
    my ($model, $nuclease_name ) = @_;

    my $nuclease = $model->retrieve( Nuclease => { name => $nuclease_name });
    return $nuclease->id;
}

sub _guided_type_id_for{
    my ($model, $guided_type_name ) = @_;

    my $guided_type = $model->retrieve( GuidedType => { name => $guided_type_name });
    return $guided_type->id;
}

sub _crispr_tracker_rna_id_for {
    my ($model, $tracker_rna_name ) = @_;

    my $crispr_tracker_rna = $model->retrieve( CrisprTrackerRna => { name => $tracker_rna_name });
    return $crispr_tracker_rna->id;
}

1;

__END__


