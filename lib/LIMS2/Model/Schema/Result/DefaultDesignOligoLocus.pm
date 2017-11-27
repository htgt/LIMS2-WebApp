package LIMS2::Model::Schema::Result::DefaultDesignOligoLocus;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::DefaultDesignOligoLocus::VERSION = '0.483';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'design_oligo_loci_ncbim37' );

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
select designs.id          as design_id,
       designs.species_id  as species_id,
       chromosomes.name    as chr_name,
       g5_locus.chr_strand as chr_strand,
       g5_locus.chr_start  as g5_start,
       g5_locus.chr_end    as g5_end,
       u5_locus.chr_start  as u5_start,
       u5_locus.chr_end    as u5_end,
       u3_locus.chr_start  as u3_start,
       u3_locus.chr_end    as u3_end,
       d5_locus.chr_start  as d5_start,
       d5_locus.chr_end    as d5_end,
       d3_locus.chr_start  as d3_start,
       d3_locus.chr_end    as d3_end,
       g3_locus.chr_start  as g3_start,
       g3_locus.chr_end    as g3_end
from designs
join species_default_assembly on species_default_assembly.species_id = designs.species_id
join design_oligos g5 on g5.design_id = designs.id and g5.design_oligo_type_id = 'G5'
join design_oligo_loci g5_locus on g5_locus.design_oligo_id = g5.id and g5_locus.assembly_id = species_default_assembly.assembly_id
join chromosomes on chromosomes.id = g5_locus.chr_id
join design_oligos u5 on u5.design_id = designs.id and u5.design_oligo_type_id = 'U5'
join design_oligo_loci u5_locus on u5_locus.design_oligo_id = u5.id and u5_locus.assembly_id = species_default_assembly.assembly_id
left outer join design_oligos u3 on u3.design_id = designs.id and u3.design_oligo_type_id = 'U3'
left outer join design_oligo_loci u3_locus on u3_locus.design_oligo_id = u3.id and u3_locus.assembly_id = species_default_assembly.assembly_id
left outer join design_oligos d5 on d5.design_id = designs.id and d5.design_oligo_type_id = 'D5'
left outer join design_oligo_loci d5_locus on d5_locus.design_oligo_id = d5.id and d5_locus.assembly_id = species_default_assembly.assembly_id
join design_oligos d3 on d3.design_id = designs.id and d3.design_oligo_type_id = 'D3'
join design_oligo_loci d3_locus on d3_locus.design_oligo_id = d3.id and d3_locus.assembly_id = species_default_assembly.assembly_id
join design_oligos g3 on g3.design_id = designs.id and g3.design_oligo_type_id = 'G3'
join design_oligo_loci g3_locus on g3_locus.design_oligo_id = g3.id and g3_locus.assembly_id = species_default_assembly.assembly_id
EOT

__PACKAGE__->add_columns(
    qw( design_id species_id chr_name chr_strand
        g5_start g5_end u5_start u5_end u3_start u3_end d5_start d5_end d3_start d3_end g3_start g3_end )
);

__PACKAGE__->belongs_to(
    "design",
    "LIMS2::Model::Schema::Result::Design",
    { id => "design_id" },
);

__PACKAGE__->meta->make_immutable;

1;


