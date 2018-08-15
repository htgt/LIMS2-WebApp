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




#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });

open (my $fh, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_location_Alleles_frequencies.txt to read';


while (my $file = <$fh>){ #foreach file from the list of file directories
    chomp $file;
    
    $file =~ m/
        Miseq_(\w+) #miseq plate number
        \/S(\d+)    #well name integer, before convert to "A01" format
        _exp(\w+)   #experiment name as string in the format "AS_EWE_E"
        /xgms;
    my ($miseq, $well, $exp) = ($1, $2, $3);


    #First, extract the plate_id, using the miseq name
    my $plate_rs = $model->schema->resultset('Plate')->search({ name => "Miseq_" . $miseq });
    my $plate_hash;
    my $plate;
    if ($plate_rs->count > 1) {
        print("Search returned multiple plates for given id \n");
        next;
    }
    elsif ($plate_rs->count <  1){
        print("Search returned empty \n");
        next;
    }

    else{
        $plate = $plate_rs->first;
        $plate_hash =$plate->as_hash;
    }



    #Then get the miseq plate id
    my $miseq_plate_hash;
    $miseq_plate_hash = $plate->miseq_details;
   


    #Plate id to well name gives well
    my $well_hash;
    my $well_name = convert_index_to_well_name($well);  
    my $well_rs = $model->schema->resultset('Well')->search(
        {   -and => 
            [
                'plate_id' => $plate_hash->{id},
                'name'     => $well_name         
            ]
        });
        
    if ($well_rs->count > 1) {
        print("Search returned multiple wells for given plate id and well name \n");
        next;
    }
    elsif ($well_rs->count <  1){
        print("Search returned empty \n");
        next;
    }
    else{
        $well_hash = $well_rs->first->as_hash;
    }


    #Query miseq experiment for name(extracted from the path and converted) and plate id
    my $miseq_experiment_hash; 
    my $miseq_experiment_rs = $model->schema->resultset('MiseqExperiment')->search(
        {   -and =>
            [   
                'miseq_id' => $miseq_plate_hash->{id},
                'name'     => $exp                    
            ]
        }
    );
    if ($miseq_experiment_rs->count > 1) {
        print("Search returned multiple miseq experiments for given miseq id and experiment name \n");
        next;
    }
    elsif ($miseq_experiment_rs->count <  1){
        print("Search returned empty \n");
        next;
    }
    else{
        $miseq_experiment_hash = $miseq_experiment_rs->first()->as_hash;
    }


    #Finally, query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.
    my $miseq_well_experiment_hash; 
    my $miseq_well_experiment_rs = $model->schema->resultset('MiseqWellExperiment')->search(
        {   -and =>
            [
                'miseq_exp_id'    => $miseq_experiment_hash->{id} ,
                'well_id'         => $well_hash->{id}
            ]
        }
    );

    if ($miseq_well_experiment_rs->count > 1) {
       print("Search returned multiple miseq well experiments for given miseq experiment id and well id \n");
       next;
    }
    elsif ($miseq_well_experiment_rs->count <  1){
       print("Search returned empty \n");
       next;
       #$miseq_well_experiment_hash = create_miseq_well_exp($model, $file, $well_hash, $miseq_experiment_hash);
    }
    else{
       $miseq_well_experiment_hash = $miseq_well_experiment_rs->first->as_hash;
    }


    my $check_rs = $model->schema->resultset('IndelDistributionGraph')->search({ id => $miseq_well_experiment_hash->{id} });
    try{

    if ($check_rs->count >= 1){
        print ("Indel graph existing already for given path: $file \n");
        next;
    }
    else{
        my $path_to_quant = $file;
        $path_to_quant =~ s/Alleles_frequency_table/Quantification_of_editing_frequency/g;
        my $sum_reads = migrate_quant_file($model, $path_to_quant, $miseq_experiment_hash);
    
        update_miseq_well_exp($model, $miseq_well_experiment_hash, $sum_reads);

        my $path_to_images = $file;
        $path_to_images =~ s/Alleles_frequency_table.txt/1b.Indel_size_distribution_percentage.png/g;
        migrate_images($model, $path_to_images, $miseq_well_experiment_hash);

        migrate_frequencies($model, $file, $miseq_well_experiment_hash);
    }
}catch{
    $DB::single=1;
print ("$file");
};
}
close($fh);





#SUBS GO HERE

sub migrate_frequencies {
    my ($model, $frequency_paths, $miseq_well_experiment_hash) = @_;

    my $counter = 0; #counts the number of frequencies within one file
    open (my $file_to_read, "<","$frequency_paths") or die "Cannot open file";

    my $header = <$file_to_read>; #grab the header line that holds the titles of the columns
    chomp $header;
    my @titles = split(/\t/, lc $header);
    my @expected_titles = ('aligned_sequence', 'nhej', 'unmodified', 'hdr', 'n_deleted', 'n_inserted', 'n_mutated', '#reads');
    my @intersection = get_intersection( [ \@titles, \@expected_titles ] );
    my %head;
    my $sum = 0;
    %head = map { lc $titles[$_] => $_ } 0 .. $#titles; #creates a hash that has all the elements of the array as keys and their index as values
    
    #check if the length of the intersection of the full array of titles is equal to the length of the array of expected titles
    #This checks that all the requested elements were found withint the header of the file
    if(scalar(@intersection) == scalar(@expected_titles)){
        while (my $line = <$file_to_read>) {
            chomp $line;
            if($counter < 10){
                $counter++;
                my @words = split(/\t/, $line); #split the space seperated values and store them in a hash
                my $row = 
                    {
                        miseq_well_experiment_id    => $miseq_well_experiment_hash->{id},
                        aligned_sequence            =>     $words  [    $head{aligned_sequence}   ],
                        nhej                        => lc  $words  [    $head{nhej}               ],
                        unmodified                  => lc  $words  [    $head{unmodified}         ],
                        hdr                         => lc  $words  [    $head{hdr}                ],
                        n_deleted                   => int $words  [    $head{n_deleted}          ],
                        n_inserted                  => int $words  [    $head{n_inserted}         ],
                        n_mutated                   => int $words  [    $head{n_mutated}          ],
                        n_reads                     => int $words  [    $head{'#reads'}           ],
                    };
                            

                $model->schema->txn_do( 
                   sub {
                      try {
                           $model->create_miseq_alleles_frequency($row);
                       }
                       catch {
                           warn "Error creating entry";
                           $model->schema->txn_rollback;
                       };
                   }
                );
              
            }
            else {last;} #to escape the while after getting 10 lines of frequencies
        }
    }
    else { warn "File: $frequency_paths is corrupt. Could not extract titles properly"; }
    close ($file_to_read);

}



sub migrate_images {
    my ($model, $image_path, $miseq_well_experiment_hash) = @_;

    my $contents = "";
    open( my $in_fh, "<", $image_path );
    binmode $in_fh;

    while ( read $in_fh, my $buf, 16384){
        $contents .= $buf;
    }
    close $in_fh;
    
    my $row = {
          id                              =>    $miseq_well_experiment_hash->{id},
          indel_size_distribution_graph   =>    $contents
      };
      $model->schema->txn_do( 
          sub {
              try {
                  $model->create_indel_distribution_graph($row);
              }
              catch {
                  warn "Error creating entry";
                  $model->schema->txn_rollback;
              };
          });
}



sub update_miseq_well_exp{
    my ($model, $miseq_well_experiment_hash, $sum_of_reads) = @_;

    my $row = {
        id                              =>    $miseq_well_experiment_hash->{id},
        well_id                         =>    $miseq_well_experiment_hash->{well_id},
        miseq_exp_id                    =>    $miseq_well_experiment_hash->{miseq_exp_id},
        classification                  =>    $miseq_well_experiment_hash->{classification},
        frameshifted                    =>    $miseq_well_experiment_hash->{frameshifted},
        status                          =>    $miseq_well_experiment_hash->{status},
        total_reads                     =>    $sum_of_reads
    };
    $model->schema->txn_do(
        sub {
            try {
                $model->update_miseq_well_experiment($row);
            }
            catch {
                warn "Error creating entry";
                $model->schema->txn_rollback;
            };
        });
}



sub migrate_quant_file {
    my ($model, $directory, $miseq_experiment_hash) = @_;

    open (my $quant_fh, '<:encoding(UTF-8)', $directory);
    my %params;
    my $line;
    my $name;
    my $number;
    #For loop skips the 1st, 2nd and 4th line of input quantification file. 
    for my $i(0..6){
        $line = <$quant_fh>;
        chomp $line;
        if ($i == 3){
            $line=~ m{- HDR:(\d+)}; #text looks like "- HDR:23424"
            $name = "hdr_reads";
            $number = $1;
            $params{$name} = $number;
        }
        elsif ($i == 4){
            $line=~ m{- Mixed HDR-NHEJ:(\d+)}; #text looks like "- Mixed HDR-NHEJ:23424"
            $name = "mixed_reads";
            $number = $1;
            try{
                $params{$name}=$number;
            }
            catch{
                warn "Error inserting params in hash";
                next;
            };
        }
        elsif ($i==6){
            $line=~ m{Total Aligned:(\d+)};
            $name = "total_reads";
            $number = $1;
            $params{$name}=$number;
        }
    }
    close $quant_fh;

    #params hash holds the info that need to be passed to the plugin
    #miseq_experiment_hash the location it should be placed in

    my $row = {
        id              =>  $miseq_experiment_hash->{id},
        miseq_id        =>  $miseq_experiment_hash->{miseq_id},
        name            =>  $miseq_experiment_hash->{name},
        gene            =>  $miseq_experiment_hash->{gene},
        nhej_reads      =>  $miseq_experiment_hash->{nhej_count},
        total_reads     =>  $miseq_experiment_hash->{read_count},
        hdr_reads       =>  $params{hdr_reads},
        mixed_reads     =>  $params{mixed_reads},
    };
    
    $model->schema->txn_do(
        sub {
            try {
                $model->update_miseq_experiment($row);
            }
            catch {
                warn "Error creating entry";
                $model->schema->txn_rollback;
            };
        });
    return $params{total_reads};
}

sub frameshift_check {
    my (@common_read) = @_; 
    my $fs_check = 0;
    unless($common_read[1]){$common_read[1]=0;}
    if ($common_read[1] eq 'True' ) {
        $fs_check = ($common_read[4] + $common_read[5]) % 3;
    }
    return $fs_check;
}



sub create_miseq_well_exp{
    my ($model, $file, $well_hash, $miseq_experiment_hash) = @_; 

    my $classification="Not Called";
    my $frameshifted=0;
    open (my $my_file, "<","$file") or die "Cannot open file";
       my $head = <$my_file>;
       chomp $head;
           
       my $most_common_line = <$my_file>;
       unless($most_common_line){$most_common_line="0";}
       chomp $most_common_line;
           
       my $second_most_common_line = <$my_file>;
       unless($second_most_common_line){$second_most_common_line="0";} 
       chomp $second_most_common_line;
           
       my $mixed_read_line = <$my_file>;
       unless($mixed_read_line){$mixed_read_line="0";} 
       chomp $mixed_read_line;
       
       close ($my_file);
       
       
       my @mixed_read = split(/\t/, $mixed_read_line);
       my $mixed_check = $mixed_read[-1];
       if ($mixed_check >= 5) {
           $frameshifted = 0;
           $classification = 'Mixed';
       }
       else {
           my @first_most_common = split(/\t/, $most_common_line); 
           my @second_most_common = split(/\t/, $second_most_common_line);
           my $fs_check = frameshift_check(@first_most_common) + frameshift_check(@second_most_common);
           if ($fs_check != 0) {
               $classification = 'Not Called';
               $frameshifted = 1;
           }
        }
    
        my $creation_params = {
                        well_id                     =>  $well_hash->{id},
                        miseq_exp_id                =>  $miseq_experiment_hash->{id},
                        classification              =>  $classification,
                        frameshifted                =>  $frameshifted,
                        status                      =>  "Plated",
                        total_reads                 =>  "0"
                    };
        my $miseq; 
        $model->schema->txn_do( 
                   sub {
                      try {
                          $miseq = $model->create_miseq_well_experiment($creation_params)->as_hash;
                          print Dumper "Created file at: $file";
                       }
                       catch {
                           warn "Error creating entry";
                           $model->schema->txn_rollback;
                       };});
        return $miseq;
}

=pod           

=head

This script reads MiSeq Crispresso format files and loads data from them into the LIMS2 database.
It takes as input a txt file that holds a list of paths to the alleles frequency table txt files.
Based on that path, the script finds the corresponding quantification and image files.

Format of input files:

=head2 Quantification
Example input file:

Quantification of editing frequency:
	- Unmodified:1898 reads
	- NHEJ:1847 reads (9 reads with insertions, 1674 reads with deletions, 1831 reads with substitutions)
	- HDR:3 reads (0 reads with insertions, 1 reads with deletions, 3 reads with substitutions)
	- Mixed HDR-NHEJ:4 reads (1 reads with insertions, 4 reads with deletions, 4 reads with substitutions)

Total Aligned:3752 reads

=head3 Alleles frequencies
Example of input file:

Aligned_Sequence	Reference_Sequence	NHEJ	UNMODIFIED	HDR	n_deleted	n_inserted	n_mutated	#Reads	%Reads
CCTAGAGAGCCAGGGCAGAGCCTCTGCAGGAGTTATGGGGTGGGTCCGTGGGTGGGTGACTTCTTAGATGAGGGTTTCATGGGAGGTACCCCGAGGGACTCTGACCATCTGTTCCCACATTCAGCAAGTTCATTCCTGAGGGCTCCCAGAGAGTGGGGCTGGTTGCCAGTCAGAAGAACGACCTGGACGCAGTGGCACTGATGCATCCCGATGGCTCTGCTGTTGTGGTCGTGCTAAACCGGTGAGGGCAATGGTGAGGTCTGGGAAGTGGGCTGAAGACAGCGTTG	CCTAGAGAGCCAGGGCAGAGCCTCTGCAGGAGTTATGGGGTGGGTCCGTGGGTGGGTGACTTCTTAGATGAGGGTTTCATGGGAGGTACCCCGAGGGACTCTGACCATCTGTTCCCACATTCAGCAAGTTCATTCCTGAGGGCTCCCAGAGAGTGGGGCTGGTTGCCAGTCAGAAGAACGACCTGGACGCAGTGGCACTGATGCATCCCGATGGCTCTGCTGTTGTGGTCGTGCTAAACCGGTGAGGGCAATGGTGAGGTCTGGGAAGTGGGCTGAAGACAGCGTTG	False	True	False	0.0	0.0	0	883	23.3969263381

=head4 Images

Takes as input a png file

=cut
