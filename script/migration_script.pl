#!/usr/bin/env perl 

use strict;
use warnings FATAL => 'all';
use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Moose;
use Text::CSV;
use LIMS2::Model::Util::Miseq qw( miseq_well_processes convert_index_to_well_name );
use List::Compare::Functional qw( get_intersection );
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data_from_file migrate_quant_file update_miseq_exp migrate_images migrate_frequencies );


#ENTRY
my $model = LIMS2::Model->new( { user => 'tasks' } );
my $sum_reads;

open( my $fh, '<:encoding(UTF-8)', 'files_paths.txt' ) or die 'Cannot open files_location_Alleles_frequencies.txt to read';
chomp(my @lines = <$fh>);
close($fh);

while (@lines) {#foreach file from the list of file directories
    my $file = shift @lines;

    print "Examined file: $file \n";

    my $data = get_data_from_file( $model, $file );
    next unless $data;

    my $path_to_quant = $file;
    $path_to_quant =~ s/Alleles_frequency_table/Quantification_of_editing_frequency/g;
    try{

        my %reads = migrate_quant_file( $model, $path_to_quant, $data->{miseq_well_experiment} );

        if ($sum_reads->{$data->{miseq_experiment}->{id}}->{total_reads}) {
            $sum_reads->{$data->{miseq_experiment}->{id}}->{total_reads} += $reads{total_reads};
        }
        else{
            $sum_reads->{$data->{miseq_experiment}->{id}}->{total_reads} = $reads{total_reads};
        }

        if ($sum_reads->{$data->{miseq_experiment}->{id}}->{nhej_reads}) {
            $sum_reads->{$data->{miseq_experiment}->{id}}->{nhej_reads} += $reads{nhej_reads};
        }
        else{
            $sum_reads->{$data->{miseq_experiment}->{id}}->{nhej_reads} = $reads{nhej_reads};
        }
    }
    catch{
        warn "Failed to migrate quant_file: $file";
    };

    #Check if there is a graph entry for examined miseq_well_exp_id ad if not update database
    my $check_rs = $model->schema->resultset('MiseqAllelesFrequency')->search( { miseq_well_experiment_id => $data->{miseq_well_experiment}->{id} } );
    if ( $check_rs->count >= 1 ) {
        print("Frequencies already loaded for given path: $file \n");
        next;
    }

    else {
        try{
            migrate_frequencies( $model, $file, $data->{miseq_well_experiment} );
            print "Successfully migrated frequencies \n";
        } catch {
            print "Failed to migrate_frequencies: $file";
        };
    }
}
close($fh);

foreach my $miseq_exp_id (keys %$sum_reads){
    my $params;
    $params = {
        id              =>  $miseq_exp_id,
        nhej_reads      =>  $sum_reads->{$miseq_exp_id}->{nhej_reads},
        total_reads     =>  $sum_reads->{$miseq_exp_id}->{total_reads},
    };
    update_miseq_exp($model, $params);
}
print "Successfully updated Miseq experiments";

=head1 NAME

migration_script.pl - script to migrate data from local file system into the database

=head1 SYNOPSIS

Requires a txt file names files_paths.txt to be present in the directory the script was ran from. Foreach of the
paths provided, this script loads the database with 10 alleles frequency entries, updates miseq miseq experiments 
and miseq well experiments.

=head1 DESCRIPTION

This script is run to update the database with new crispresso submission data. Uses the local file system to extract
information and then updates the database. 
It is advised to run through the use of "migration.sh" script.
