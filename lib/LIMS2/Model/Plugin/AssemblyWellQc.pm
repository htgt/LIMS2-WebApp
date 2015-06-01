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



1;

__END__
