package LIMS2::Model::Plugin::QcTemplate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Scalar::Util qw( blessed );
use namespace::autoclean;
use JSON qw( decode_json );

requires qw( schema check_params throw );

sub _instantiate_qc_template {
    my ( $self, $params ) = @_;

    if ( blessed( $params ) and $params->isa( 'LIMS2::Model::Schema::Result::QcTemplate' ) ) {
        return $params;
    }

    my $validated_params = $self->check_params(
        { slice( $params, qw( qc_template_id ) ) },
        { qc_template_id => { validate => 'integer', rename => 'id' } }
    );

    $self->retrieve( QcTemplate => $validated_params );
}

sub pspec_create_qc_template {
    return {
        name  => { validate => 'plate_name' },
        wells => { optional => 1 }
    };
}

sub create_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_template );

    my $qc_template = $self->schema->resultset( 'QcTemplate' )->create(
        { slice_def( $validated_params, qw( name ) ) }
    );

    while ( my ( $well_name, $well_params ) = each %{ $validated_params->{wells} || {} } ) {
        next unless defined $well_params and keys %{$well_params};
        $well_params->{qc_template_id} = $qc_template->id;
        $well_params->{name}           = $well_name;
        $self->create_qc_template_well( $well_params, $qc_template );
    }

    $self->log->debug( 'created qc template plate : ' . $qc_template->name );

    return $qc_template;
}

sub pspec_create_qc_template_well {
    return {
        qc_template_id => { validate => 'integer' },
        name           => { validate => 'well_name' },
        eng_seq_method => { validate => 'non_empty_string' },
        eng_seq_params => { validate => 'json' },
    };
}

sub create_qc_template_well {
    my ( $self, $params, $qc_template ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_template_well );

    $qc_template ||= $self->_instantiate_qc_template( $validated_params );

    $self->log->debug( 'create_qc_template_well: '
                       . $qc_template->name
                       . '_' . $validated_params->{name} );

    my $eng_seq_params = $self->canonicalise_eng_seq_params( $validated_params->{eng_seq_params} );

    my $qc_eng_seq = $self->schema->resultset('QcEngSeq')->find_or_create(
        {
           eng_seq_method => $validated_params->{eng_seq_method},
           eng_seq_params => $eng_seq_params,
        }
    );

    my $qc_template_well = $qc_template->create_related(
        qc_template_wells => {
            slice_def( $validated_params, qw( name ) ),
            qc_eng_seq_id => $qc_eng_seq->id,
        }
    );

    $self->log->debug( 'created qc_template_well with id: ' . $qc_template_well->id );

    return $qc_template_well;
}

sub canonicalise_eng_seq_params {
    my ( $self, $eng_seq_params ) = @_;

    my $params = decode_json( $eng_seq_params );
    my $json = JSON->new->utf8->canonical->encode( $params );

    return $json;
}

sub pspec_retrieve_qc_template {
    return {
        id   => { validate => 'integer', optional => 1 },
        name => { validate => 'existing_qc_template_name', optional => 1 },
        REQUIRE_SOME => {
            qc_template_id_or_name => [ 1, qw/id name/ ],
        }
    };
}

sub retrieve_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template );
    my $qc_template;

    if ( $validated_params->{id} ) {
        $qc_template = $self->retrieve( QcTemplate => $validated_params );
    }
    else {
       $qc_template = $self->schema->resultset('QcTemplate')->search_rs(
            {
                name => $validated_params->{name}
            },
            {
                order_by => { -desc => 'created_at' }
            }
        )->first;
    }

    return $qc_template;
}

sub pspec_retrieve_newest_qc_template_created_before {
    return {
        name           => { validate => 'non_empty_string' },
        created_before => { validate => 'date_time', post_filter => 'parse_date_time' },
    };
}

sub retrieve_newest_qc_template_created_before {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template_created_before );

    my $qc_template = $self->schema->resultset('QcTemplate')->search(
        {
            name       => $validated_params->{name},
            created_at => { '<' => $validated_params->{created_before} },
        },
        {
            order_by => { desc => 'created_at' },
            columns  => [ qw( name created_at ) ],
            rows     => 1
        }
    )->single;

    return $qc_template;
}

1;

__END__
