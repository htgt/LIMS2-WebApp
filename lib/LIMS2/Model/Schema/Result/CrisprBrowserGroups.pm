package LIMS2::Model::Schema::Result::CrisprBrowserGroups;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprBrowserGroups::VERSION = '0.452';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::CrisprBrowserGroups

=head1 DESCRIPTION

Custom view that retrieves crispr group information for each crispr locus.
This is used to bring back crispr group data for the genome browser.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'crispr_browser_groups' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
select
    cgc.crispr_group_id,
    cgc.crispr_id,
    cl.assembly_id,
    cl.chr_id,
    cl.chr_start,
    cl.chr_end,
    cl.chr_strand,
    cr.pam_right
from crispr_group_crisprs cgc
join crispr_loci cl on cl.crispr_id = cgc.crispr_id
join crisprs cr on cgc.crispr_id = cr.id
where cl.chr_start >= ? and cl.chr_end <= ?
and cl.chr_id = ?
and cl.assembly_id = ?
order by cgc.crispr_group_id, cl.chr_start
EOT

__PACKAGE__->add_columns(
    qw/
        crispr_group_id
        crispr_id
        assembly_id
        chr_id
        chr_start
        chr_end
        chr_strand
        pam_right
    /
);

__PACKAGE__->set_primary_key( "crispr_group_id" );

__PACKAGE__->meta->make_immutable;

1;

