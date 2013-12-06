package LIMS2::Model::Schema::Result::GibsonDesignBrowser;

=head1 NAME

LIMS2::Model::Schema::Result::GibsonDesignBrowser

=head1 DESCRIPTION

Custom view that stores design oligo information for each design.
This is used to bring back Gibson design data for the genome browser.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );

__PACKAGE__->table( 'design_browser_pairs' );

__PACKAGE__->result_source_instance->is_virtual(1);

=head Bind params
Bind params in the order:

start
end
chromosome
assembly
=cut

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
select a.design_oligo_id        oligo_id
	, a.assembly_id             assembly_id
	, a.chr_start               chr_start
	, a.chr_end                 chr_end
	, a.chr_id                  chr_id
	, a.chr_strand              chr_strand
	, b.design_id               design_id
	, b.design_oligo_type_id    oligo_type_id
	, c.design_type_id          design_type_id
from design_oligo_loci a
	
join design_oligos b
	on (a.design_oligo_id = b.id)
join designs c
	on (b.design_id = c.id)
	and (c.design_type_id = 'gibson')

where a.chr_start >= ? and a.chr_end <= ?
    and a.chr_id = ?
	and a.assembly_id = ?
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
    /
);

__PACKAGE__->set_primary_key( "oligo_id" );

__PACKAGE__->meta->make_immutable;

1;


