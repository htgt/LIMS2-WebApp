package LIMS2::Model::Plugin::QcSeqRead;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Scalar::Util qw( blessed );
use namespace::autoclean;

requires qw( schema check_params throw );

sub _instantiate_qc_seq_read {
    my ( $self, $params ) = @_;

    if ( blessed( $params ) and $params->isa( 'LIMS2::Model::Schema::Result::QcSeqRead' ) ) {
        return $params;
    }

    my $validated_params = $self->check_params(
        { slice( $params, qw( qc_seq_read_id ) ) },
        { qc_seq_read_id => { validate => 'qc_seq_read_id', rename => 'id' } }
    );

    $self->retrieve( QcSeqRead => $validated_params );
}

sub pspec_create_qc_seq_read {
    return {
        id                    => { validate => 'qc_seq_read_id' },
        qc_sequencing_project => { validate => 'plate_name' },
        description           => { validate => 'non_empty_string' },
        seq                   => { validate => 'dna_seq' },
        length                => { validate => 'integer' },
    };
}

sub create_qc_seq_read {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_seq_read );

    $self->find_or_create_qc_sequencing_project( { name => $validate_params->{qc_sequencing_project}  } )

    my $qc_seq_read = $self->schema->resultset('QcSeqRead')->create(
        {
            slice_def( $validated_params,
                qw( id description seq length qc_sequencing_project ) ),
        }
    );

    $self->log->debug( 'created qc_seq_read with id: ' . $qc_seq_read->id );

    return $qc_seq_read;
}

sub pspec_retrieve_qc_seq_read {
    return {
        id => { validate => 'qc_seq_read_id' },
    };
}

sub retrieve_qc_seq_read {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_seq_read );

    my $qc_seq_read = $self->retrieve( QcSeqRead => $validated_params );

    return $qc_seq_read;
}

1;

__END__
