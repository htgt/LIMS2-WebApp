package LIMS2::Catalyst::Controller::REST;

use Moose;
use Scalar::Util qw( blessed );
use HTTP::Status qw( :constants );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

sub end :Private {
    my ( $self, $c ) = @_;

    if ( @{$c->error} ) {
        $c->forward( 'handle_error' );
    }    
    
    my $entity = $c->stash->{ $self->{stash_key} };
    $c->stash->{ $self->{stash_key} } = $self->_recursive_to_hash( $entity );
    
    $c->forward( 'do_serialize' );
}

sub _recursive_to_hash {
    my ( $self, $entity ) = @_;

    if ( blessed( $entity ) and $entity->can( 'as_hash' ) ) {
        return $entity->as_hash;
    }
    elsif ( ref $entity eq 'ARRAY' ) {
        for ( @{$entity} ) {
            $_ = $self->_recursive_to_hash( $_ );
        }
    }
    elsif ( ref $entity eq 'HASH' ) {
        for ( values %{$entity} ) {
            $_ = $self->_recursive_to_hash( $_ );
        }
    }
    
    return $entity;
}

sub handle_error :Private {
    my ( $self, $c ) = @_;

    my @errors = @{$c->error};
    $c->log->error($_) for @errors;
    $c->clear_errors;

    # Assume the first error in the list is the most interesting one
    my $error = $errors[0];

    if ( blessed( $error ) and $error->isa( 'LIMS2::Model::Error' ) ) {
        $self->handle_lims2_model_error( $c, $error );
    }
    else {
        $self->error_status( $c, HTTP_INTERNAL_SERVER_ERROR, { error => "$error" } );
    }
}

sub error_status {    
    my ( $self, $c, $status_code, $entity ) = @_;

    $c->response->status( $status_code );
    $self->_set_entity( $c, $entity );
}
    
sub handle_lims2_model_error {
    my ( $self, $c, $error ) = @_;

    my %entity = ( error => $error->message, class => blessed $error );
    
    if ( $error->isa( 'LIMS2::Model::Error::Authorization' ) ) {
        return $self->error_status( $c, HTTP_FORBIDDEN, \%entity );
    }
    
    if ( $error->isa( 'LIMS2::Model::Error::Validation' ) ) {
        if ( my $results = $error->results ) {            
            $entity{missing} = [ $results->missing ]
                if $results->has_missing;
            $entity{invalid} = { map { $_ => $results->invalid($_) } $results->invalid }
                if $results->has_invalid;
            $entity{unknown} = [ $results->unknown ]
                if $results->has_unknown;
        }        
        return $self->error_status( $c, HTTP_BAD_REQUEST, \%entity );
    }
    
    if ( $error->isa( 'LIMS2::Model::Error::InvalidState' ) ) {
        return $self->error_status( $c, HTTP_CONFLICT, \%entity );
    }

    if ( $error->isa( 'LIMS2::Model::Error::NotFound' ) ) {
        $entity{entity_class}  = $error->entity_class;
        $entity{search_params} = $error->search_params;
        return $self->error_status( $c, HTTP_NOT_FOUND, \%entity );
    }

    # Default to an internal server error
    $self->error_status( $c, HTTP_INTERNAL_SERVER_ERROR, { error => $error->message } );
}

sub do_serialize :ActionClass('Serialize') {}

__PACKAGE__->meta->make_immutable;

1;

__END__
