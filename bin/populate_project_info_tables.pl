#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use JSON;

Log::Log4perl->easy_init($DEBUG);

my $model = LIMS2::Model->new( user => 'tasks' );
my $schema = $model->schema;

my @projects = $schema->resultset('Project')->all;

foreach my $project (@projects){
	my $info = decode_json($project->allele_request);
	
	DEBUG "Populating project info for ".$project->id."\n";
	
	$project->update_or_create_related('project_information',
	    {
	    	gene_id        => $info->{gene_id},
	    	targeting_type => $info->{targeting_type},
	    }
	);
	
	foreach my $type qw(first second){
		if ($info->{$type."_allele_cassette_function"}){
	        $project->update_or_create_related('project_alleles',
	            {
	            	allele_type       => $type,
	            	cassette_function => $info->{$type."_allele_cassette_function"},
	            	mutation_type     => $info->{$type."_allele_mutation_type"},
	            },
	            {
	            	key => 'primary',
	            },
	        );
		}
	}
	
}

