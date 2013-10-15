package LIMS2::Model::Schema::Result::DesignTargetCrisprs;

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
SELECT 
    dt.id as design_target_id,
    dt.gene_id as gene_id,
    dt.ensembl_gene_id as ensembl_gene_id,
    dt.ensembl_exon_id as ensembl_exon_id,
    c.id as crispr_id
FROM design_targets dt
INNER JOIN crispr_loci cl
ON cl.assembly_id = dt.assembly_id
AND cl.chr_id = dt.chr_id
AND cl.chr_start > dt.chr_start
AND cl.chr_end < dt.chr_end
INNER JOIN crisprs c
ON c.id = cl.crispr_id
EOT

__PACKAGE__->add_columns(
    qw( design_target_id gene_id ensembl_gene_id ensembl_exon_id crispr_id )
);

__PACKAGE__->belongs_to(
    "crispr",
    "LIMS2::Model::Schema::Result::Crispr",
    { id => "crispr_id" },
);

__PACKAGE__->meta->make_immutable;

1;


