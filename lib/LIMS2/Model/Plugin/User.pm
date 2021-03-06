package LIMS2::Model::Plugin::User;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Const::Fast;
use Crypt::SaltedHash;
use LIMS2::Model::Util::PgUserRole qw( create_pg_user );
use namespace::autoclean;
use Digest::SHA;
use Crypt::PBKDF2;
use Try::Tiny;

requires qw( schema check_params throw retrieve );

{

    const my $MIN_PW_LEN => 8;
    const my $PW_LEN => 10;
    const my @PW_CHARS => ( 'A' .. 'Z', 'a' .. 'z', '0' .. '9' );

    sub pwgen {
        my ($class, $len) = @_;
        if ( !$len || $len < $MIN_PW_LEN ) {
            $len = $PW_LEN;
        }
        return join( '', map { $PW_CHARS[ int rand @PW_CHARS ] } 1 .. $len );
    }
}

has _role_id_for => (
    isa        => 'HashRef',
    traits     => ['Hash'],
    lazy_build => 1,
    handles    => { role_id_for => 'get' }
);

sub _build__role_id_for {
    my $self = shift;

    return +{ map { $_->name => $_->id } $self->schema->resultset('Role')->all };
}

sub user_id_for {
    my ( $self, $user_name ) = @_;

    my %search = ( name => $user_name );
    my $user = $self->schema->resultset('User')->find( \%search )
        or $self->throw(
        NotFound => {
            entity_class  => 'User',
            search_params => \%search
        }
        );

    return $user->id;
}

sub list_users {
    my ($self) = @_;

    my @users = $self->schema->resultset('User')
        ->search( {}, { prefetch => { user_roles => 'role' }, order_by => { -asc => 'me.name' } } );

    return \@users;
}

sub list_roles {
    my ($self) = @_;

    my @roles = $self->schema->resultset('Role')->search( {}, { order_by => { -asc => 'me.name' } } );

    return \@roles;
}



sub pspec_create_user {
    return {
        name     => { validate => 'user_name' },
        password => { validate => 'non_empty_string' },
        roles    => { validate => 'existing_role', optional => 1 },
    };
}

sub create_user {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_user );

    my $csh = Crypt::SaltedHash->new( algorithm => "SHA-1" );
    $csh->add( $validated_params->{password} );
    $csh->add( $validated_params->{user_preference} );

    my $user = $self->schema->resultset('User')->create(
        {   name     => $validated_params->{name},
            password => $csh->generate
        }
    );

    for my $role_name ( @{ $validated_params->{roles} || [] } ) {
        $user->create_related( user_roles => { role_id => $self->role_id_for($role_name) } );
    }

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            create_pg_user( $dbh, @{$validated_params}{qw(name roles)} );
        }
    );
    return $user;
}

sub pspec_set_user_roles {
    return {
        name  => { validate => 'existing_user' },
        roles => { validate => 'existing_role' }
    };
}

sub set_user_roles {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_user_roles );

    my $user = $self->retrieve( User => { name => $validated_params->{name} } );

    my @role_ids = map { $self->role_id_for($_) } @{ $validated_params->{roles} };

    $user->user_roles_rs->delete;
    for my $role_id (@role_ids) {
        $user->create_related( user_roles => { role_id => $role_id } );
    }

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            create_pg_user( $dbh, $user->name, $validated_params->{roles} );
        }
    );

    return $user;
}

sub pspec_set_user_password {
    return {
        name     => { validate => 'existing_user' },
        password => { validate => 'non_empty_string' }
    };
}

sub set_user_password {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_user_password );

    my $user = $self->retrieve( User => { name => $validated_params->{name} } );

    my $csh = Crypt::SaltedHash->new( algorithm => "SHA-1" );
    $csh->add( $validated_params->{password} );

    $user->update( { password => $csh->generate } );

    return $user;
}

sub pspec_set_user_active_status {
    return {
        name   => { validate => 'user_name' },
        active => { validate => 'boolean' }
    };
}

sub set_user_active_status {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_user_active_status );

    my $user = $self->schema->resultset('User')->find($validated_params)
        or $self->throw(
        NotFound => {
            entity_class  => 'User',
            search_params => $validated_params
        }
        );

    $user->update( { active => $validated_params->{active} } );

    return $user;
}

sub enable_user {
    my ( $self, $params ) = @_;

    $params->{active} = 1;

    return $self->set_user_active_status($params);
}

sub disable_user {
    my ( $self, $params ) = @_;

    $params->{active} = 0;

    return $self->set_user_active_status($params);
}

sub pspec_retrieve_user_preferences {
    return {
        name            => { validate => 'user_name', optional => 1 },
        id              => { validate => 'integer',   optional => 1 },
        REQUIRE_SOME    => { name_or_id => [ 1, qw( name id ) ] }
    }
}

sub retrieve_user_preferences {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_user_preferences, ignore_unknown => 1 );

    my $user = $self->retrieve( User => { slice_def $validated_params, qw( id name ) }, { prefetch => 'user_preference' } );
    if (!$user->user_preference){
    $user->create_related(user_preference => { default_species_id => 'Human', default_pipeline_id => 'pipeline_II'} );
    }
    return $user->user_preference;
}

sub pspec_set_user_preferences {
    return {
        name            => { validate => 'user_name', optional => 1 },
        id              => { validate => 'integer',   optional => 1 },
        default_species => { validate => 'existing_species', optional => 1, default => 'Human' },
        default_pipeline => { validate => 'existing_pipeline', optional => 1, default => 'pipeline_II' },
        REQUIRE_SOME    => { name_or_id => [ 1, qw( name id ) ] }
    }
}

sub set_user_preferences
{
    my ( $self, $params ) = @_;
    my $user_preference = $self->retrieve( UserPreference => { user_id => $params->{id} });
    $params->{default_species} = $params->{default_species} || $user_preference->default_species_id;
    $params->{default_pipeline} = $params->{default_pipeline} || $user_preference->default_pipeline_id;
    my $validated_params = $self->check_params( $params, $self->pspec_set_user_preferences );
    my $prefs = $self->retrieve_user_preferences( $validated_params );
    if ( $prefs->default_species_id ne $validated_params->{default_species} ){
        $prefs->update( { default_species_id => $validated_params->{default_species} } );
    }
    if ( $prefs->default_pipeline_id ne $validated_params->{default_pipeline} ){
        $prefs->update( { default_pipeline_id => $validated_params->{default_pipeline} } );
    }
    return $prefs;
}

sub pspec_change_user_password {
    return {
        id                   => { validate   => 'integer' },
        new_password         => { validate   => 'password_string' },
        new_password_confirm => { validate   => 'password_string' },
    };
}

sub change_user_password {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_change_user_password );

    $self->throw( Validation => 'new password and password confirm values do not match' )
        unless $validated_params->{new_password} eq $validated_params->{new_password_confirm};

    my $user = $self->retrieve( User => { id => $validated_params->{id} } );

    my $csh = Crypt::SaltedHash->new( algorithm => "SHA-1" );
    $csh->add( $validated_params->{new_password} );
    $csh->add( $validated_params->{password} );
    $user->update( { password => $csh->generate } );

    return $user;
}

sub pspec_update_user_password{

    return {
	id                   => { validate   => 'integer' },

    };
}

sub update_user_password{
    my ( $self, $params ) = @_;
    my $validated_params = $self->check_params( $params, $self->pspec_update_user_password );
    my $user = $self->retrieve( User => { id => $validated_params->{id} } );

    my $csh = Crypt::SaltedHash->new( algorithm => "SHA-1" );

    $user->update( { password => $csh->generate } );

    return $user;

    }

sub pspec_create_api_key {
    return {
        id          => { validate => 'integer' },
        access_key  => { validate => 'uuid' },
        secret_key  => { validate => 'uuid' },
    };
}

sub create_api_key {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_api_key );

    my $user = $self->retrieve( User => { id => $validated_params->{id} } );
    my $pbk = Crypt::PBKDF2->new(
        hash_class => 'HMACSHA3',
        iterations => 1000,
        output_len => 20,
        salt_len => 4,
    );

    $user->update(
        {
            access_key => $validated_params->{access_key},
            secret_key => $pbk->generate($validated_params->{secret_key}),
        }
    );

    return $user;
}

1;

__END__
