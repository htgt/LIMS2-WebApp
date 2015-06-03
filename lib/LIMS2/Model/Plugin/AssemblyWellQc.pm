package LIMS2::Model::Plugin::AssemblyWellQc;

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

    return;
}

1;

__END__
