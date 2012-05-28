package LIMS2::Model::Plugin::User;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice );
use Const::Fast;
use Crypt::SaltedHash;
use LIMS2::Model::Util;
use namespace::autoclean;

requires qw( schema check_params throw );

{
    
    const my $PW_LEN => 10;
    const my @PW_CHARS => ( 'A'..'Z', 'a'..'z', '0'..'9' );

    sub pwgen {
        my ( $class ) = @_;
        return join( '', map { $PW_CHARS[int rand @PW_CHARS] } 1..$PW_LEN );
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

sub pspec_create_user {
    return {
        name     => { validate => 'user_name' },
        password => { validate => 'non_empty_string' },
        roles    => { validate => 'existing_role' }
    };
}

sub create_user {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_user );
    
    my $csh = Crypt::SaltedHash->new(algorithm=>"SHA-1");
    $csh->add( $validated_params->{password} );
    
    my $user = $self->schema->resultset('User')->create(
        {
            name     => $validated_params->{name},
            password => $csh->generate
        }
    );

    for my $role_name ( @{ $validated_params->{roles} } ) {
        $user->create_related( user_roles => { role_id => $self->role_id_for($role_name) } );
    }

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            LIMS2::Model::Util::create_pg_user( $dbh, @{$validated_params}{ qw(name roles) } );            
        }
    );

    return $user;
}

sub pspec_delete_user {
    return { name => { validate => 'user_name' } };
}

sub delete_user {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_delete_user );

    my $user = $self->schema->resultset('User')->find($validated_params)
        or $self->throw(
        NotFound => {
            entity_class  => 'User',
            search_params => $validated_params
        }
        );

    $user->user_roles->delete;
    $user->delete;

    return 1;
}

1;

__END__
