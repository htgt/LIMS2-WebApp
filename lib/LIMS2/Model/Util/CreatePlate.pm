package LIMS2::Model::Util::CreatePlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreatePlate::VERSION = '0.315';
}
## use critic


use strict;
use warnings FATAL => 'all';
use feature "switch";

use Sub::Exporter -setup => {
    exports => [
        qw(
              create_plate_well
              merge_plate_process_data
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Model::Util qw( well_id_for );
use List::MoreUtils qw( uniq );
use LIMS2::Exception;
use Data::Dumper;

use LIMS2::Model::Constants qw( $MAX_CRISPR_GROUP_SIZE );

sub pspec_create_plate_well {
    return {
        well_name    => { validate => 'well_name' },
        process_type => { validate => 'existing_process_type' },
        accepted     => { validate => 'boolean', optional => 1 },
    };
}

# input will be in the format a user trying to create a plate will use
# we need to convert this into a format expected by create_well
sub create_plate_well {
    my ( $model, $params, $plate ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec_create_plate_well, ignore_unknown => 1 );
    my $parent_well_ids = find_parent_well_ids( $model, $params );

    my %well_params = (
        plate_name => $plate->name,
        well_name  => $validated_params->{well_name},
        created_by => $plate->created_by->name,
        created_at => $plate->created_at->iso8601,
        accepted   => $validated_params->{accepted},
    );

    # the remaining params are specific to the process
    delete @{$params}{qw( well_name process_type accepted )};

    $well_params{process_data} = $params;
    $well_params{process_data}{type} = $validated_params->{process_type};
    $well_params{process_data}{input_wells} = [ map { { id => $_ } } @{$parent_well_ids} ];

    $model->create_well( \%well_params, $plate );

    return;
}

sub pspec_find_parent_well_ids {
    my $pspec = {
        parent_plate         => { validate => 'plate_name', optional => 1 },
        parent_plate_version => { validate => 'integer',    optional => 1 },
        parent_well          => { validate => 'well_name',  optional => 1 },
        xep_plate            => { validate => 'plate_name', optional => 1 },
        xep_well             => { validate => 'well_name',  optional => 1 },
        dna_plate            => { validate => 'plate_name', optional => 1 },
        dna_well             => { validate => 'well_name',  optional => 1 },
        final_pick_plate     => { validate => 'plate_name', optional => 1 },
        final_pick_well      => { validate => 'well_name',  optional => 1 },
        crispr_vector_plate  => { validate => 'plate_name', optional => 1 },
        crispr_vector_well   => { validate => 'well_name',  optional => 1 },
        crispr_vector1_plate => { validate => 'plate_name', optional => 1 },
        crispr_vector1_well  => { validate => 'well_name',  optional => 1 },
        crispr_vector2_plate => { validate => 'plate_name', optional => 1 },
        crispr_vector2_well  => { validate => 'well_name',  optional => 1 },
        design_plate         => { validate => 'plate_name', optional => 1 },
        design_well          => { validate => 'well_name',  optional => 1 },
        crispr_plate         => { validate => 'plate_name', optional => 1 },
        crispr_well          => { validate => 'well_name',  optional => 1 },
        DEPENDENCY_GROUPS    => { parent   => [qw( parent_plate parent_well )] },
        DEPENDENCY_GROUPS    => { vector   => [qw( vector_plate vector_well )] },
        DEPENDENCY_GROUPS    => { allele   => [qw( allele_plate allele_well )] },
    };

    # Add fields for all posssible crispr_vector plate and well columns
    my $num = 1;
    while ($num <= $MAX_CRISPR_GROUP_SIZE){
        my $plate = 'crispr_vector'.$num.'_plate';
        my $well = 'crispr_vector'.$num.'_well';

        $pspec->{$plate} = { validate => 'plate_name', optional => 1 };
        $pspec->{$well} = { validate => 'well_name',  optional => 1 };
        $num++;
    }

    return $pspec;
}

sub find_parent_well_ids {
    my ( $model, $params ) = @_;


    my $validated_params
        = $model->check_params( $params, pspec_find_parent_well_ids, ignore_unknown => 1 );

    my @parent_well_ids;

    for ( $params->{process_type} ) {
        when ( 'second_electroporation' ) {
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{xep_plate},
                    well_name  => substr( $validated_params->{xep_well}, -3 )
                }
            );
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{dna_plate},
                    well_name  => substr( $validated_params->{dna_well}, -3 )
                }
            );
        }
        when ( 'single_crispr_assembly' ) {
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{final_pick_plate},
                    well_name  => substr( $validated_params->{final_pick_well}, -3 )
                }
            );
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{crispr_vector_plate},
                    well_name  => substr( $validated_params->{crispr_vector_well}, -3 )
                }
            );
        }
        when ( 'paired_crispr_assembly' ) {
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{final_pick_plate},
                    well_name  => substr( $validated_params->{final_pick_well}, -3 )
                }
            );
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{crispr_vector1_plate},
                    well_name  => substr( $validated_params->{crispr_vector1_well}, -3 )
                }
            );
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{crispr_vector2_plate},
                    well_name  => substr( $validated_params->{crispr_vector2_well}, -3 )
                }
            );
        }
        when ( 'group_crispr_assembly' ){
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{final_pick_plate},
                    well_name  => substr( $validated_params->{final_pick_well}, -3 )
                }
            );
            my $num = 1;
            while ($num <= $MAX_CRISPR_GROUP_SIZE){
                my $plate = 'crispr_vector'.$num.'_plate';
                my $well = 'crispr_vector'.$num.'_well';

                $num++;

                next unless ($validated_params->{$plate} and $validated_params->{$well});

                push @parent_well_ids, well_id_for(
                    $model, {
                        plate_name => $validated_params->{$plate},
                        well_name => substr( $validated_params->{$well}, -3 )
                    }
                );
            }
        }
        when ( 'oligo_assembly' ){
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{design_plate},
                    well_name  => substr( $validated_params->{design_well}, -3 )
                }
            );
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{crispr_plate},
                    well_name  => substr( $validated_params->{crispr_well}, -3 )
                }
            );
        }
        when ( 'create_di' ) {
            return [];
        }
        when ( 'create_crispr' ) {
            return [];
        }
        when ( 'xep_pool' ) {
            foreach my $well_name ( @{$params->{'parent_well_list'}} ) {
                push @parent_well_ids, well_id_for(
                    $model, {
                        plate_name => $validated_params->{'parent_plate'},
                        well_name => $well_name
                    }
                );
            }
            delete @{$params}{'parent_well_list'};
        }
        default {
            push @parent_well_ids, well_id_for(
                $model, {
                    plate_name => $validated_params->{parent_plate},
                    plate_version => $validated_params->{parent_plate_version},
                    well_name  => substr( $validated_params->{parent_well}, -3 ),
                }
            );

            delete @{$params}{qw( parent_plate parent_well )};
        }
    }

    return \@parent_well_ids;
}

## no critic(RequireFinalReturn)
sub merge_plate_process_data {
    my ( $well_data, $plate_data ) = @_;

    for my $process_field ( keys %{ $plate_data } ) {
        # insert plate process data only if it is not present in well data
        $well_data->{$process_field} = $plate_data->{$process_field}
            if !exists $well_data->{$process_field}
                || !$well_data->{$process_field};
    }

    #recombinse data needs to be array ref
    $well_data->{recombinase} = [ delete $well_data->{recombinase} ]
        if exists $well_data->{recombinase};
}
## use critic

1;

__END__
