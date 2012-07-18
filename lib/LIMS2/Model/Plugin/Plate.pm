package LIMS2::Model::Plugin::Plate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use LIMS2::Model::Util qw( sanitize_like_expr );
use Const::Fast;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub list_plate_types {
    my $self = shift;

    return [ $self->schema->resultset('PlateType')->search( {}, { order_by => { -asc => 'id' } } ) ];
}

sub pspec_list_plates {
    return {
        plate_name => { validate => 'non_empty_string',    optional => 1 },
        plate_type => { validate => 'existing_plate_type', optional => 1 },
        page       => { validate => 'integer',             optional => 1, default => 1 },
        pagesize   => { validate => 'integer',             optional => 1, default => 15 }
    }
}

sub list_plates {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_list_plates );

    my %search;

    if ( $validated_params->{plate_name} ) {
        $search{'me.name'} = { -like => '%' . sanitize_like_expr( $validated_params->{plate_name} ) . '%' };
    }

    if ( $validated_params->{plate_type} ) {
        $search{'me.type_id'} = $validated_params->{plate_type};
    }

    my $resultset = $self->schema->resultset('Plate')->search(
        \%search,
        {
            prefetch => [ 'created_by' ],
            order_by => { -desc => 'created_at' },
            page     => $validated_params->{page},
            rows     => $validated_params->{pagesize}
        }
    );

    return ( [ $resultset->all ], $resultset->pager );
}

sub pspec_create_plate {
    return {
        name        => { validate => 'plate_name' },
        type        => { validate => 'existing_plate_type', rename => 'type_id' },
        description => { validate => 'non_empty_string', optional => 1 },
        created_by => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' },
        comments   => { optional => 1 },
        wells      => { optional => 1 }
    };
}

sub pspec_create_plate_comment {
    return {
        comment_text => { validate => 'non_empty_string' },
        created_by   => {
            validate    => 'existing_user',
            post_filter => 'user_id_for',
            rename      => 'created_by_id'
        },
        created_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

sub create_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_plate );

    my $plate = $self->schema->resultset('Plate')->create(
        { slice_def( $validated_params, qw( name type_id description created_by_id created_at ) ) }
    );

    #for my $c ( @{ $validated_params->{comments} || [] } ) {
        #my $validated_c = $self->check_params( $c, $self->pspec_create_plate_comment );
        #$plate->create_related( plate_comments =>
                #{ slice_def( $validated_c, qw( comment_text created_by_id created_at ) ) } );
    #}

    $self->create_plate_wells( $validated_params->{wells}, $plate )
        if @{ $validated_params->{wells} };

    return $plate;
}

sub pspec_retrieve_plate {
    return {
        name         => { validate => 'plate_name', optional => 1, rename => 'me.name' },
        id           => { validate => 'integer', optional => 1, rename => 'me.id' },
        type         => { validate => 'existing_plate_type', optional => 1, rename => 'me.type_id' },
        REQUIRE_SOME => { name_or_id => [ 1, qw( name id ) ] }
    };
}

sub retrieve_plate {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_retrieve_plate, ignore_unknown => 1 );

    return $self->retrieve( Plate => { slice_def $validated_params, qw( me.name me.id me.type_id ) } );
}

sub pspec_set_plate_assay_complete {
    my $self = shift;
    return +{
        %{ $self->pspec_retrieve_plate },
        completed_at => { validate => 'date_time', optional => 1, post_filter => 'parse_date_time' }
    };
}

sub set_plate_assay_complete {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_set_plate_assay_complete );

    my $plate = $self->retrieve_plate( $validated_params );

    for my $well ( $plate->wells ) {
        $self->set_well_assay_complete(
            {
                id           => $well->id,
                completed_at => $validated_params->{completed_at}
            }
        );
    }

    return $plate;
}

{

    const my %HANDLER_FOR_TRANSITION => (
        #ROOT => {
            #DESIGN  => sub { 'create_di' }
        #},
        #DESIGN => {
            #INT     => sub { 'int_recom' },
        #},
        #INT => {
            #INT     => sub { 'rearray' },
            #POSTINT => compute_process_type( qw( 2w_gateway 3w_gateway ) ),
            #FINAL   => compute_process_type( qw( 2w_gateway 3w_gateway ) ),
        #},
        #POSTINT => {
            #POSTINT => compute_process_type( qw( 2w_gateway recombinase rearray ) ),
            #FINAL   => compute_process_type( qw( 2w_gateway recombinase ) )
        #},
        #FINAL => {
            #FINAL   => compute_process_type( qw( recombinase rearray ) ),
            #DNA     => sub { 'dna_prep' }
        #},
        DNA => {
            EP => 'first_electroporation'
        },
        EP => {
            EP_PICK => 'colony_pick', # EPD in HTGT
            XEP     => 'recombinase', # Flp excision
        },
        EP_PICK => {
            FP => 'freeze'
        },
        XEP => {
            XEP_POOL => 'colony_pool',
            XEP_PICK => 'colony_pick', # EPD in HTGT
            SEP      => 'second_electroporation'
        },
        SEP => {
            SEP_PICK => 'colony_pick',
            SEP_POOL => 'colony_pool',
        },
        SEP_PICK => {
            SFP => 'freeze'
        },
    );

    sub process_type_for {
        my ( $self, $parent_type, $child_type ) = @_;

        die "No process configured for transition from $parent_type to $child_type"
            unless exists $HANDLER_FOR_TRANSITION{$parent_type}
                and exists $HANDLER_FOR_TRANSITION{$parent_type}{$child_type};

        return $HANDLER_FOR_TRANSITION{$parent_type}{$child_type};
    }
}

sub create_plate_wells {
    my ( $self, $wells, $plate ) = @_;

    for my $well ( @{ $wells } ) {
        my $parent_well = $self->retrieve_well(
            {
                plate_name => $well->{parent_plate},
                well_name => $well->{parent_well}
            }
        );

        my $process_type = $self->process_type_for( $parent_well->plate->type_id, $plate->type_id );

        my %well_params = (
            plate_name => $plate->name,
            well_name  => $well->{well_name},
            created_by => $plate->created_by->name,
            created_at  => $plate->created_at->iso8601,
        );
        my %process_data = (
            type      => $process_type,
            cell_line => $well->{cell_line},
            input_wells =>[
                { id => $parent_well->id }
            ]
        );
        $well_params{process_data} = \%process_data;

        $self->create_well( \%well_params, $plate );
    }
}

1;

__END__
