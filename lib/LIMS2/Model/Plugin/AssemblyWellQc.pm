package LIMS2::Model::Plugin::AssemblyWellQc;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::AssemblyWellQc::VERSION = '0.327';
}
## use critic


use strict;
use warnings FATAL => 'all';
use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use Try::Tiny;

requires qw( schema check_params throw retrieve log trace );

=head

A Catalyst plugin that provides methods for updating well_assembly_qc values

=cut

sub _pspec_update_assembly_qc_well{
    return {
    	well_id => { validate => 'integer' },
    	type    => { validate => 'assembly_qc_type' },
        value   => { validate => 'assembly_qc_value', optional => 1 },
        MISSING_OPTIONAL_VALID => 1,
    };
}

sub update_assembly_qc_well{
    my ($self, $params) = @_;

    my $validated_params = $self->check_params($params, $self->_pspec_update_assembly_qc_well);

    my $well = $self->retrieve_well({ id => $validated_params->{well_id} });

    my $plate_type = $well->plate->type_id;
    unless($plate_type eq 'ASSEMBLY'){
    	die "Cannot add assembly well QC to well $well on $plate_type plate";
    }

    my $qc;
    if($validated_params->{value}){
        $qc = $well->well_assembly_qcs->update_or_create({
            qc_type => $validated_params->{type},
            value   => $validated_params->{value},
        });
    }
    else{
        # No value so we unset the QC result
        $well->delete_related('well_assembly_qcs',{ qc_type => $validated_params->{type} });
    }

    return $qc;
}

1;

__END__
