package LIMS2::Model::Plugin::QcSequencingProject;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Scalar::Util qw( blessed );
use namespace::autoclean;

requires qw( schema check_params throw );
# TODO: move this code into QcSeqRead plugin

# this subroutine is not used anywhere?
sub _instantiate_qc_sequencing_project {
    my ( $self, $params ) = @_;

    if ( blessed( $params ) and $params->isa( 'LIMS2::Model::Schema::Result::QcSequencingProject' ) ) {
        return $params;
    }

    my $validated_params = $self->check_params(
        { slice( $params, qw( qc_sequencing_project ) ) },
        { qc_sequencing_project => { validate => 'plate_name', rename => 'name' } }
    );

    $self->retrieve( QcSequencingProject => $validated_params );
}

sub pspec_find_or_create_qc_sequencing_project {
    return {
        name => { validate => 'plate_name' },
    };
}

sub find_or_create_qc_sequencing_project {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_sequencing_project );

    my $qc_sequencing_project = $self->schema->resultset( 'QcSequencingProject' )->find_or_create(
        { slice_def( $validated_params, qw( name ) ) }
    );

    return $qc_sequencing_project;
}

1;

__END__
