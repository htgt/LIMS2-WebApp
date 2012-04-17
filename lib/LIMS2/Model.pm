package LIMS2::Model;

use strict;
use warnings FATAL => 'all';

use Moose;
require LIMS2::Model::DBConnect;
require LIMS2::Model::FormValidator;
require DateTime::Format::ISO8601;
require Module::Pluggable::Object;
use Scalar::Util qw( blessed );
use namespace::autoclean;

# XXX TODO: authorization checks?

# This assumes we're using Catalyst::Model::Factory::PerRequest and
# setting the audit_user when the LIMS2::Model object is
# instantiated. If necessary, we could make audit_user rw and allow
# the model object to be reused.

has audit_user => (
    is      => 'ro',
    isa     => 'Str',
    trigger => \&_audit_user_set
);

sub _audit_user_set {
    my ( $self, $user, $old_user ) = @_;

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            $dbh->do( 'SET SESSION ROLE ' . $dbh->quote_identifier( $user ) );
        }
    );
}

has user => (
    is  => 'ro',
    isa => 'Str',
);

has schema => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema',
    lazy_build => 1,
    handles    => [ 'txn_do', 'txn_rollback' ]
);

sub _build_schema {
    my $self = shift;

    my $user = $self->user
        or confess "user must be specified for database login";

    return LIMS2::Model::DBConnect->connect( 'LIMS2_DB', $user );
}

has form_validator => (
    is         => 'ro',
    isa        => 'LIMS2::Model::FormValidator',
    lazy_build => 1,
    handles    => [ 'check_params' ]
);

sub _build_form_validator {
    my $self = shift;

    return LIMS2::Model::FormValidator->new( model => $self );
}

has eng_seq_builder => (
    is         => 'ro',
    isa        => 'EngSeqBuilder',
    lazy_build => 1
);

sub _build_eng_seq_builder {
    my $self = shift;

    require EngSeqBuilder;
    return EngSeqBuilder->new(
        configfile            => $ENV{ENG_SEQ_BUILDER_CONFIG},
        max_vector_seq_length => 250000
    );
}

has ensembl_util => (
    isa        => 'LIMS2::Util::EnsEMBL',
    lazy_build => 1,
    handles => {
        map { 'ensembl_' . $_ => $_ }
            qw( db_adaptor gene_adaptor slice_adaptor transcript_adaptor constrained_element_adaptor repeat_feature_adaptor )
    }
);

sub _build_ensembl_util {
    require LIMS2::Util::EnsEMBL;
    # Could specify species in constructor, default species => 'mouse'
    return LIMS2::Util::EnsEMBL->new;
}

sub throw {
    my ( $self, $error_class, $args ) = @_;

    if ( $error_class !~ /::/ ) {
        $error_class = 'LIMS2::Model::Error::' . $error_class;
    }

    eval "require $error_class"
        or confess "Load $error_class: $!";

    my $err = $error_class->new( $args );

    $self->log->error( $err->as_string );

    $err->throw;
}

sub parse_date_time {
    my ( $self, $date_time ) = @_;

    if ( not defined $date_time ) {
        return;
    }
    elsif ( blessed( $date_time ) and $date_time->isa( 'DateTime' ) ) {
        return $date_time;
    }
    else {
        DateTime::Format::ISO8601->parse_datetime( $date_time );
    }

}

sub plugins {
    my $class = shift;

    Module::Pluggable::Object->new( search_path => [ $class . '::Plugin' ] )->plugins;
}

sub retrieve {
    my ( $self, $entity_class, $search_params, $search_opts ) = @_;

    $search_opts ||= {};

    my @objects = $self->schema->resultset( $entity_class )->search( $search_params, $search_opts );

    if ( @objects == 1 ) {
        return $objects[0];
    }
    elsif ( @objects == 0 ) {
        $self->throw( NotFound => { entity_class => $entity_class, search_params => $search_params } );
    }
    else {
        $self->throw( Implementation => "Retrieval of $entity_class returned " . @objects . " objects" );
    }
}

sub retrieve_list {
    my ( $self, $entity_class, $search_params, $search_opts ) = @_;

    $search_opts ||= {};

    my @objects = $self->schema->resultset( $entity_class )->search( $search_params, $search_opts );

    if ( @objects == 0 ) {
        $self->throw( NotFound => { entity_class => $entity_class, search_params => $search_params } );
    }
    else {
        return \@objects;
    }
}

with ( qw( MooseX::Log::Log4perl ), __PACKAGE__->plugins );

1;
