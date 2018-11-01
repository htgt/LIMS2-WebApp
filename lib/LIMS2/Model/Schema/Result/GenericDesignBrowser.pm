package LIMS2::Model::Schema::Result::GenericDesignBrowser;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::GenericDesignBrowser::VERSION = '0.515';
}
## use critic


=head1 NAME

LIMS2::Model::Schema::Result::GenericDesignBrowser

=head1 DESCRIPTION

Custom view that stores design oligo information for each design, for designs in a specific locus
It is generic, because it doesn't just relate to Gibson designs.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'design_data_generic' );

__PACKAGE__->result_source_instance->is_virtual(1);

=head Bind params
Bind params in the order:

start
end
chromosome
assembly
=cut

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
with des as (select
	  a.design_oligo_id         oligo_id
	, b.design_id               design_id
    , c.design_type_id	        design_type_id
    , a.assembly_id             assembly_id
    , d.gene_id                 gene_id
from design_oligo_loci a
	
join design_oligos b
	on (a.design_oligo_id = b.id)
join designs c
	on (b.design_id = c.id)
join gene_design d
    on (b.design_id = d.design_id)

where a.chr_start >= ? and a.chr_end <= ?
    and a.chr_id = ?
	and a.assembly_id = ? )
select distinct d_o.design_id		    design_id
	, d_o.id				            oligo_id
	, d_o.design_oligo_type_id	        oligo_type_id
	, d_l.assembly_id		            assembly_id
	, d_l.chr_start			            chr_start
	, d_l.chr_end			            chr_end
	, d_l.chr_id			            chr_id
	, d_l.chr_strand			        chr_strand
    , des.design_type_id                design_type_id
    , des.gene_id                       gene_id
	
from des
join design_oligos d_o
	on ( des.design_id = d_o.design_id )
join design_oligo_loci d_l
	on ( d_l.design_oligo_id = d_o.id and des.assembly_id = d_l.assembly_id )
order by chr_start
EOT

__PACKAGE__->add_columns(
    qw/
        oligo_id      
        assembly_id   
        chr_start     
        chr_end       
        chr_id        
        chr_strand
        design_id     
        oligo_type_id 
        design_type_id
        gene_id
    /
);

#__PACKAGE__->set_primary_key( "oligo_id" );

__PACKAGE__->meta->make_immutable;

1;


