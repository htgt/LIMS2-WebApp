#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;

my $model = LIMS2::Model->new({ user => 'tasks' });

my @crispr_designs = $model->schema->resultset('CrisprDesign')->all;

foreach my $crispr_design (@crispr_designs){
	print STDERR "crispr_design ".$crispr_design->id.": \n";
	my $existing = $model->schema->resultset('Experiment')->find({
        design_id => $crispr_design->design_id,
        crispr_id => $crispr_design->crispr_id,
        crispr_pair_id => $crispr_design->crispr_pair_id,
        crispr_group_id => $crispr_design->crispr_group_id,
	});

	if($existing){
		print STDERR "Updating experiment ".$existing->id." with plated flag ".$crispr_design->plated."\n";
		$existing->update({ plated => $crispr_design->plated });
	}
	else{
		# create new experiment with gene from design
		my ($gene_id) = $crispr_design->design->gene_ids;
		my $new_experiment = $model->create_experiment({
            gene_id         => $gene_id,
            design_id       => $crispr_design->design_id,
            crispr_id       => $crispr_design->crispr_id,
            crispr_pair_id  => $crispr_design->crispr_pair_id,
            crispr_group_id => $crispr_design->crispr_group_id,
            plated          => $crispr_design->plated,
		});
		print STDERR "Created new experiment for gene $gene_id with id ".$new_experiment->id."\n";
	}
}