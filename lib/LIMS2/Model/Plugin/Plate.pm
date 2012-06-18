package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub pspec_create_plate {
    return {
        name         => { validate => 'plate_name' },
        type         => { validate => 'existing_plate_type', rename => 'type_id' },
        process_type => { validate => 'existing_process_type' },
        process_data => { validate => 'hashref', optional => 1, default => {} },
        description  => { validate => 'non_empty_string', optional => 1 },
        created_by   => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at   => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        comments     => { optional => 1 },
        wells        => { optional => 1 }
    }
}

sub pspec_create_plate_comment {
    return {
        comment_text  => { validate => 'non_empty_string' },
        created_by    => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at    => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    }
}

sub pspec_create_well {
    return {
        well_name      => { validate => 'well_name' },
        created_by     => { validate => 'existing_user', post_filter => 'user_id_for', rename => 'created_by_id' },
        created_at     => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        process_data   => { validate => 'hashref', optional => 1, default => {} }
    }
}

sub create_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_plate );

    my $process_type = $self->schema->resultset( 'ProcessType' )->find( { id => $validated_params->{process_type} } );    
    
    my $plate = $self->schema->resultset( 'Plate' )->create(
        {
            slice_def( $validated_params, qw( name type_id description created_by_id created_at ) ),
        }
    );

    for my $c ( @{ $validated_params->{comments} || [] } ) {
        my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        $plate->create_related( plate_comments => $validated_c );
    }

    while ( my ( $well_name, $well_params ) = each %{ $validated_params->{wells} || {} } ) {
        next unless defined $well_params and keys %{$well_params};
        $well_params->{well_name}    = $well_name;
        $well_params->{created_at} ||= $params->{created_at};
        $well_params->{created_by} ||= $params->{created_by};
        my $validated_well_params = $self->check_params( { slice_def $well_params, qw( well_name created_at created_by process_data ) },
                                                         $self->pspec_create_well );
        my $well = $plate->create_related( wells => \$validated_well_params );
        # Merge plate-level and well-level process data, with well data taking precedence
        my %process_data = (
            %{ $validated_params->{process_data} },
            %{ $validated_well_params->{process_data} },
            type         => $process_type->id,
            output_wells => [ { id => $well->id } ]
        );
        $self->create_process( \%process_data );        
    }

    # XXX Should this return profile-specific data?
    return $plate;
}

1;

__END__
