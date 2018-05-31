package LIMS2::Model::Schema::Result::ExonCrisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::ExonCrisprs::VERSION = '0.504';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::ExonCrisprs

=head1 DESCRIPTION

Custom view that joins crisprs to exons.
Should only be used with a list of exon_ids.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'exon_crisprs' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
WITH dt as (
    SELECT
        ensembl_exon_id,
        chr_id,
        (chr_start-200) as chr_start,
        (chr_end+200) as chr_end
    FROM (SELECT unnest(?::text[]) AS id) x
    JOIN design_targets ON design_targets.ensembl_exon_id=x.id
)
SELECT DISTINCT
    dt.ensembl_exon_id,
    cl.crispr_id
FROM dt
JOIN crispr_loci cl
    ON  cl.chr_id=dt.chr_id
    AND cl.chr_start>dt.chr_start
    AND cl.chr_start<dt.chr_end
EOT

__PACKAGE__->add_columns(
    qw( ensembl_exon_id crispr_id )
);

__PACKAGE__->set_primary_key( "ensembl_exon_id", "crispr_id" );

__PACKAGE__->belongs_to(
    "crispr",
    "LIMS2::Model::Schema::Result::Crispr",
    { id => "crispr_id" },
);

__PACKAGE__->meta->make_immutable;

1;

