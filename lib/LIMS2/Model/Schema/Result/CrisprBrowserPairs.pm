package LIMS2::Model::Schema::Result::CrisprBrowserPairs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprBrowserPairs::VERSION = '0.385';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::CrisprBrowserPairs

=head1 DESCRIPTION

Custom view that stores crispr pair information for each crispr locus.
This is used to bring back crispr pair data for the genome browser.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'crispr_browser_pairs' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
select b.id "pair_id"
	, a.crispr_id "left_crispr_id"
	, d.seq "left_crispr_seq"
	, a.chr_start "left_crispr_start"
	, a.chr_end "left_crispr_end"
	, d.pam_right "left_crispr_pam_right"
	, c.crispr_id "right_crispr_id"
	, e.seq "right_crispr_seq"
	, c.chr_start "right_crispr_start"
	, c.chr_end "right_crispr_end"
	, e.pam_right "right_crispr_pam_right"

	from crispr_loci a
	join crispr_pairs b on a.crispr_id = b.left_crispr_id
	join crispr_loci c on b.right_crispr_id = c.crispr_id
	join crisprs d on b.left_crispr_id = d.id
	join crisprs e on b.right_crispr_id = e.id
	where a.chr_start >= ? and a.chr_end <= ?
        and a.chr_id = ?
		and a.assembly_id = ?
        and c.assembly_id = ?
    order by a.crispr_id desc
EOT

__PACKAGE__->add_columns(
    qw/
        pair_id
        left_crispr_id
        left_crispr_seq
        left_crispr_start
        left_crispr_end
        left_crispr_pam_right
        right_crispr_id
        right_crispr_seq
        right_crispr_start
        right_crispr_end
        right_crispr_pam_right
    /
);

__PACKAGE__->set_primary_key( "pair_id" );

__PACKAGE__->meta->make_immutable;

1;


