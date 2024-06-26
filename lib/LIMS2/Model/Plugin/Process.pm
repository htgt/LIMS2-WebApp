package LIMS2::Model::Plugin::Process;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use LIMS2::Model::Util::CreateProcess qw( process_fields process_plate_types link_process_wells create_process_aux_data create_process_aux_data_recombinase );
use namespace::autoclean;
use Const::Fast;
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_process {
    return {
        type         => { validate => 'existing_process_type' },
        input_wells  => { optional => 1 },
        output_wells => { optional => 1 },
        dna_template => { optional => 1 }, #TODO Change to existing_cell_line
    };
}

sub create_process {
    my ( $self, $params ) = @_;
    my $validated_params
        = $self->check_params( $params, $self->pspec_create_process, ignore_unknown => 1 );
    my $process
        = $self->schema->resultset('Process')->create( { type_id => $validated_params->{type}, dna_template => $validated_params->{dna_template} } );
    $self->log->info("Id: " . $process->{_column_data}->{id});

    link_process_wells( $self, $process, $validated_params );
    $self->log->debug("link_process_wells successful");

    delete @{$params}{qw( type input_wells output_wells )};

    create_process_aux_data( $self, $process, $params );
    $self->log->debug("create_process_aux_data successful");

    return $process;
}

sub pspec_add_recombinase_data {
    return {
        plate_name  => { validate => 'plate_name' },
        plate_name  => { validate => 'existing_plate_name' },
        well_name   => { validate => 'well_name' },
        recombinase => { validate => 'existing_recombinase' },
    };
}

sub add_recombinase_data {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_add_recombinase_data, ignore_unknown => 1 );

    my $well = $self->retrieve_well( $validated_params );
    my @process = $well->parent_processes;

    $self->throw( NotFound => "could not retrieve process" ) unless @process;
    $self->throw( Validation => "cannot apply recombinase to this well" ) unless scalar(@process) == 1;
    $self->throw( Validation => "invalid plate type; can only add recombinase to EP_PICK plates" ) unless $well->plate_type eq 'EP_PICK';

    # converts recombinase to an array to satisfy create_process_aux_data_recombinase method
    $validated_params->{recombinase} = [$validated_params->{recombinase}];
    create_process_aux_data_recombinase( $self, $validated_params, $process[0] );

    return 1;
}

sub upload_recombinase_file_data {

    my ( $self, $recombinase_data_fh ) = @_;
    my $recombinase_data = parse_csv_file( $recombinase_data_fh );
    my $error_log;
    my $line = 1;

    foreach my $recombinase (@{$recombinase_data}){
        $line++;
        $self->throw( Validation => "invalid column names or data" ) unless $recombinase->{plate_name} && $recombinase->{well_name} && $recombinase->{recombinase};
        try{
            add_recombinase_data( $self, $recombinase );
        }
        catch{
            $error_log
                .= 'line '
                . $line
                . ': plate '
                . $recombinase->{plate_name}
                . ', well '
                . $recombinase->{well_name}
                . ' , recombinase '
                . $recombinase->{recombinase}
                . ' ERROR: '
                . $_;
        };
    }

    LIMS2::Exception::Validation->throw(
        "$error_log"
    )if $error_log;

    return 1;
}

sub pspec_delete_process {
    return {
        id => { validate => 'integer' }
    }
}

sub delete_process {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_process );

    my $process = $self->retrieve( Process => { id => $validated_params->{id} } );

    my @related_resultsets = qw(  process_backbone process_bacs process_cassette process_design
                                  process_input_wells process_output_wells process_recombinases
                                  process_cell_line process_crispr process_nuclease
                                  process_crispr_pair process_crispr_group
                                  process_global_arm_shortening_design
                                  process_crispr_tracker_rna
                                  process_parameters process_guided_type
                                );

    for my $rs ( @related_resultsets ) {
        $process->search_related_rs( $rs )->delete;
    }

    $process->delete;

    return 1;
}

sub list_process_types {
    my ($self) = @_;

    return [
        $self->schema->resultset('ProcessType')->search( {}, { order_by => { -asc => 'id' } } ) ];
}

sub pspec_get_process_fields {
    return {
        process_type => { validate => 'existing_process_type' },
    };
}

sub get_process_fields {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_get_process_fields );

    return process_fields( $self, $validated_params->{process_type} );
}

sub pspec_get_process_plate_types {
    return {
        process_type => { validate => 'existing_process_type' },
    };
}

sub get_process_plate_types {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_get_process_plate_types );

    return process_plate_types( $self, $validated_params->{process_type} );
}

sub pspec_append_process {
    return {
        type         => { validate => 'existing_process_type' },
        input_wells  => { optional => 1 },
        output_wells => { optional => 1 },
    };
}

sub append_process {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params($params, $self->pspec_append_process);
    my @output_wells = $validated_params->{output_wells};
    my @well_rs;
    foreach my $output (@output_wells) {
        push @well_rs, $self->model('Golgi')->schema->resultset('Well')->find({ id => $output });
    }

    return;
}

sub get_processes_for_wells {
    # NOTE - This will return *all* processes that have the passed in input and
    # output wells. This might include cases where there are multiple input or
    # output wells. This may or may not be the desired behaviour.
    my ( $self, $params ) = @_;
    my $input_well = $self->retrieve_well($params->{input_well});
    my $output_well = $self->retrieve_well($params->{output_well});
    my @input_child_processes = $input_well->child_processes();
    my @output_parent_processes = $output_well->parent_processes();
    my @processes_for_both_wells = ();
    foreach my $process (@input_child_processes) {
        if (grep {$_->id eq $process->id} @output_parent_processes) {
            push(@processes_for_both_wells, $process);
        }
    }
    return @processes_for_both_wells;
}

1;

__END__
