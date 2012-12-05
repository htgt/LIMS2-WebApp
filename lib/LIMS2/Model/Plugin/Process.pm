package LIMS2::Model::Plugin::Process;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Process::VERSION = '0.034';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use LIMS2::Model::Util::CreateProcess qw( process_fields process_plate_types link_process_wells create_process_aux_data );
use namespace::autoclean;
use Const::Fast;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_process {
    return {
        type         => { validate => 'existing_process_type' },
        input_wells  => { optional => 1 },
        output_wells => { optional => 1 }
    };
}

sub create_process {
    my ( $self, $params ) = @_;

    my $validated_params
        = $self->check_params( $params, $self->pspec_create_process, ignore_unknown => 1 );

    my $process
        = $self->schema->resultset('Process')->create( { type_id => $validated_params->{type} } );

    link_process_wells( $self, $process, $validated_params );

    delete @{$params}{qw( type input_wells output_wells )};

    create_process_aux_data( $self, $process, $params );

    return $process;
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
                                  process_cell_line
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

1;

__END__
