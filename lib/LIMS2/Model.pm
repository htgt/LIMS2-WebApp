package LIMS2::Model;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::VERSION = '0.353';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
require LIMS2::Model::DBConnect;
require LIMS2::Model::FormValidator;
require DateTime::Format::ISO8601;
require Module::Pluggable::Object;
use LIMS2::Model::Util::PgUserRole qw( db_name );
use Data::Dump qw( pp );
use CHI;
use Scalar::Util qw( blessed );
use Log::Log4perl qw( :easy );
use namespace::autoclean;

# XXX TODO: authorization checks?

has audit_user => (
    is      => 'ro',
    isa     => 'Str',
);

has user => (
    is  => 'ro',
    isa => 'Str',
);

has schema => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema',
    lazy_build => 1,
    handles    => ['txn_rollback']
);

sub _build_schema {
    my $self = shift;

    my $user = $self->user
        or confess "user must be specified for database login";

    my $schema = LIMS2::Model::DBConnect->connect( 'LIMS2_DB', $user );

    if ( my $audit_user = $self->audit_user ) {
        $schema->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                DEBUG("LIMS2::Model::_build_schema() - Switching to session role: '" . $audit_user . "'");
                $dbh->do( 'SET SESSION ROLE ' . $dbh->quote_identifier($audit_user) );
            }
        );
    }

    return $schema;
}

sub txn_do {
    my ( $self, $code_ref, @args ) = @_;

    return $self->schema->txn_do( $code_ref, $self, @args );
}

sub software_version {
    return $LIMS2::Model::VERSION || 'dev';
}

sub database_name {
    return db_name( shift->schema->storage->dbh );
}

# has_XXX_cache attributes may be defined in a plugin; their builder
# method will call this one with an appropriate namespace.  See
# LIMS2::Model::Plugin::Gene for an example

sub _build_cache {
    my ( $self, $namespace ) = @_;

    my %chi_args = (
        driver     => 'Memory',
        max_size   => '1m',
        expires_in => '8 hours',
        namespace  => $namespace,
        global     => 1
    );

    if ( my $root_dir = $ENV{LIMS2_MODEL_CACHE_ROOT} ) {
        $chi_args{driver}   = 'FastMmap';
        $chi_args{root_dir} = $root_dir;
    }

    return CHI->new( %chi_args );
}

has form_validator => (
    is         => 'ro',
    isa        => 'LIMS2::Model::FormValidator',
    lazy_build => 1,
    handles    => ['check_params', 'clear_cached_constraint_method']
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
        configfile            => $ENV{ENG_SEQ_BUILDER_CONF},
        max_vector_seq_length => 250000
    );
}

has ensembl_util => (
    isa        => 'LIMS2::Util::EnsEMBL',
    lazy_build => 1,
    handles    => {
        map { 'ensembl_' . $_ => $_ }
            qw( db_adaptor gene_adaptor slice_adaptor transcript_adaptor exon_adaptor constrained_element_adaptor repeat_feature_adaptor )
    }
);

sub _build_ensembl_util {
    require LIMS2::Util::EnsEMBL;

    # Could specify species in constructor, default species => 'mouse'
    return LIMS2::Util::EnsEMBL->new;
}

sub solr_util {
    my $self = shift;
    require LIMS2::Util::Solr;
    return LIMS2::Util::Solr->new(@_);
}

sub solr_query {
    my $self = shift;
    return $self->solr_util->query(@_);
}

## no critic(RequireFinalReturn)
sub throw {
    my ( $self, $error_class, $args ) = @_;

    if ( $error_class !~ /::/ ) {
        $error_class = 'LIMS2::Exception::' . $error_class;
    }

    eval "require $error_class"
        or confess "Load $error_class: $!";

    my $err = $error_class->new($args);

    $self->log->error( $err->as_string );

    $err->throw;
}
## use critic

sub parse_date_time {
    my ( $self, $date_time ) = @_;

    if ( not defined $date_time ) {
        return;
    }
    elsif ( blessed($date_time) and $date_time->isa('DateTime') ) {
        return $date_time;
    }
    else {
        return DateTime::Format::ISO8601->parse_datetime($date_time);
    }

}

sub plugins {
    my $class = shift;

    return Module::Pluggable::Object->new(
        search_path => [ $class . '::Plugin', 'WebAppCommon::Plugin' ],
        except => 'LIMS2::Model::Plugin::Design')->plugins;
}

## no critic(RequireFinalReturn)
sub retrieve {
    my ( $self, $entity_class, $search_params, $search_opts ) = @_;

    $search_opts ||= {};

    my @objects = $self->schema->resultset($entity_class)->search( $search_params, $search_opts );

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
## use critic

## no critic(RequireFinalReturn)
sub retrieve_list {
    my ( $self, $entity_class, $search_params, $search_opts ) = @_;

    $search_opts ||= {};

    my @objects = $self->schema->resultset($entity_class)->search( $search_params, $search_opts );

    if ( @objects == 0 ) {
        $self->throw( NotFound => { entity_class => $entity_class, search_params => $search_params } );
    }
    else {
        return \@objects;
    }
}
## use critic

sub trace {
    my ( $self, @args ) = @_;

    if ( $self->log->is_trace ) {
        my $mesg = join "\n", map { ref $_ ? pp( $_ ) : $_ } @args;
        $self->log->trace( $mesg );
    }

    return;
}

with( qw( MooseX::Log::Log4perl ), __PACKAGE__->plugins );

1;
