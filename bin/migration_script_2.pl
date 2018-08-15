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

open (my $fh, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';


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
       print("Trying to create miseq well exp for path: $file \n");
       create_miseq_well_exp($model, $file, $well_hash, $miseq_experiment_hash);
    }
    else{
        #$miseq_well_experiment_hash = $miseq_well_experiment_rs->first->as_hash;
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
        $model->schema->txn_do( 
                   sub {
                      try {
                          $model->create_miseq_well_experiment($creation_params);
                          print Dumper "Created file at: $file";
                       }
                       catch {
                           warn "Error creating entry";
                           $model->schema->txn_rollback;
                       };
                   });    
               return;
           }

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


