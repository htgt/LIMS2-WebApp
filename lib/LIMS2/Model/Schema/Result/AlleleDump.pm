package LIMS2::Model::Schema::Result::AlleleDump;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::AlleleDump::VERSION = '0.528';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::AlleleDump

=head1 DESCRIPTION

Custom view that returns data used in the AlleleDump report

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'allele_dump' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
with gene_ids as (
	select p.gene_id, ps.sponsor_id
	from projects p, project_sponsors ps
	where ps.sponsor_id = 'Cre Knockin'
    and ps.project_id = p.id
	order by p.gene_id
)
select
     gene_ids.sponsor_id        "eucomm"
    ,design_gene_id             "mgi"
    ,design_id                  "design_id"
    ,int_plate_name             "pcs_plate"
    ,int_well_name              "pcs_well"
    ,int_qc_seq_pass            "pcs_qc_result"
    ,int_well_accepted          "pcs_distribute"
    ,final_pick_plate_name      "pgs_plate"
    ,final_pick_well_name       "pgs_well"
    ,final_pick_cassette_name   "cassette"
    ,final_pick_backbone_name   "backbone"
    ,final_pick_qc_seq_pass     "pgs_qc_result"
    ,final_pick_well_accepted   "pgs_distribute"
    ,ep_pick_plate_name||'_'||ep_pick_well_name "epd"
    ,ep_first_cell_line_name    "es_cell_line"
    ,ep_pick_well_accepted      "epd_distribute"
    ,fp_plate_name||'_'||fp_well_name "fp"
from summaries
join gene_ids on summaries.design_gene_id = gene_ids.gene_id
where final_pick_cassette_cre is true
and ep_pick_plate_name is not null
EOT

__PACKAGE__->add_columns(
    qw/
        eucomm
        mgi
        design_id
        pcs_plate
        pcs_well
        pcs_qc_result
        pcs_distribute
        pgs_plate
        pgs_well
        cassette
        backbone
        pgs_qc_result
        pgs_distribute
        epd
        es_cell_line
        epd_distribute
        fp
    /
);

__PACKAGE__->set_primary_key( "epd" );

__PACKAGE__->meta->make_immutable;

1;

