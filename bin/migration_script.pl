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
use LIMS2::Model::Util::ImportCrispressoQC qw( 
                                                get_data_from_file 
                                                migrate_quant_file 
                                                update_miseq_well_exp 
                                                migrate_images 
                                                migrate_frequencies
                                            );

#ENTRY
my $model = LIMS2::Model->new( { user => 'tasks' } );

open( my $fh, '<:encoding(UTF-8)', 'files_paths.txt' )
    or die 'Cannot open files_location_Alleles_frequencies.txt to read';

while ( my $file = <$fh> ) {    #foreach file from the list of file directories
    chomp $file;

    my $data = get_data_from_file( $model, $file );
    next unless $data;

    #Check if there is a graph entry for examined miseq_well_exp_id ad if not update database
    my $check_rs
        = $model->schema->resultset('IndelDistributionGraph')->search( { id => $data->{miseq_well_experiment}->{id} } );
    if ( $check_rs->count >= 1 ) {
        print("Indel graph existing already for given path: $file \n");
        next;
    }
    else {
        my $path_to_quant = $file;
        $path_to_quant =~ s/Alleles_frequency_table/Quantification_of_editing_frequency/g;
        try{
            my $sum_reads = migrate_quant_file( $model, $path_to_quant, $data->{miseq_experiment} );
            update_miseq_well_exp( $model, $data->{miseq_well_experiment}, $sum_reads );
        }
        catch{
            warn "Failed to migrate quant_file/update_miseq_well_experiment: $file";
            open (my $fh, '>', 'error_log.txt') or die 'Cannot open files_location.txt to write';
            print $fh "Failed to migrate quant_file: $file";
            close($fh);
        };

        my $path_to_images = $file;
        $path_to_images =~ s/Alleles_frequency_table.txt/1b.Indel_size_distribution_percentage.png/g;
        try{
            migrate_images( $model, $path_to_images, $data->{miseq_well_experiment} );  
        }
        catch{
            warn "Failed to migrate_images";
            open (my $fh, '>', 'error_log.txt') or die 'Cannot open files_location.txt to write';
            print $fh "Failed to migrate_images: $file";
            close($fh);
        };

        try{
            migrate_frequencies( $model, $file, $data->{miseq_well_experiment} );
        }
        catch{
            warn "Failed to migrate_images";
            open (my $fh, '>', 'error_log.txt') or die 'Cannot open files_location.txt to write';
            print $fh "Failed to migrate_frequencies: $file";
            close($fh);
        };

        print("$file");
    }
}
close($fh);
