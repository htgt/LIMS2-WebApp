package LIMS2::Model::Schema::Result::DesignTargetCrisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::DesignTargetCrisprs::VERSION = '0.425';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::DesignTargetCrisprs

=head1 DESCRIPTION

Custom view that joins crisprs to design targets.
Should only be used with a subset of design targets.

The results may be inaccurate in the rare cases that two exons that lie
close to each other have both been targeted and crisprs for both targets exist.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'design_target_crisprs' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
SELECT DISTINCT
    dt.id as design_target_id,
    c.id as crispr_id
FROM design_targets dt
INNER JOIN crispr_loci cl
ON cl.assembly_id = dt.assembly_id
AND cl.chr_id = dt.chr_id
AND cl.chr_start > ( dt.chr_start - 200 )
AND cl.chr_end < ( dt.chr_end + 200 )
INNER JOIN crisprs c
ON c.id = cl.crispr_id
EOT

__PACKAGE__->add_columns(
    qw( design_target_id crispr_id )
);

__PACKAGE__->set_primary_key( "design_target_id", "crispr_id" );

__PACKAGE__->belongs_to(
    "crispr",
    "LIMS2::Model::Schema::Result::Crispr",
    { id => "crispr_id" },
);

__PACKAGE__->belongs_to(
    "design_target",
    "LIMS2::Model::Schema::Result::DesignTarget",
    { id => "design_target_id" },
);

__PACKAGE__->meta->make_immutable;

1;


