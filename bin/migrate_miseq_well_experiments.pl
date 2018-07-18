#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
#use Text::File::Basename;
use LIMS2::Model::Util::Miseq qw( miseq_well_processes convert_index_to_well_name );


my $model = LIMS2::Model->new({ user => 'tasks' });

#my @files = `find /warehouse/team229_wh01/lims2_managed_miseq_data/. -name Alleles_frequency_table.txt`;
my @files = `find ~/dev/LIMS2-WebApp/tmp/ -name Alleles_frequency_table.txt`;
foreach my $file ( @files ){
    chomp $file;
    $file =~ m/
        Miseq_(\d+) #miseq plate number
        \/S(\d+)    #well name integer, before convert to "A01" format
        _exp(\w+)   #experiment name as string in the format "AS_EWE_E"
        /xgms;
    my ($miseq, $well, $exp) = ($1, $2, $3);

    #First, extract the plate_id, using the miseq name
    
    my $plate_rs = $model->schema->resultset('Plate')->search({ name => "Miseq_" . $miseq });
    my $plate_hash;
    my $plate;
    if ($plate_rs->count > 1) {
        print('Search returned multiple plates for given id');
        exit();
    }
    elsif ($plate_rs->count <  1){
        print('Search returned empty');
        exit();
    }

    else{
        $plate = $plate_rs->next();
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
        print('Search returned multiple wells for given plate id and well name');
        exit();
    }
    elsif ($well_rs->count <  1){
        print('Search returned empty');
        exit();
    }
    else{
        $well_hash = $well_rs->next()->as_hash;
    }

print Dumper "Everything up until here is bug free";
$DB::single=1;


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
        print('Search returned multiple miseq experiments for given miseq id and experiment name');
        exit();
    }
    elsif ($miseq_experiment_rs->count <  1){
        print('Search returned empty');
        exit();
    }
    else{
        $miseq_experiment_hash = $miseq_experiment_rs->next()->as_hash;
    }


#Finally, query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.
$DB::single=1;

    #my $miseq_well_experiment_hash; 
    #my $miseq_well_experiment_rs = $model->schema->resultset('MiseqWellExperiment')->search(
    #    { 'miseq_exp_id'    => $miseq_experiment_hash->{id} },
    #   { 'well_id'         => $well_hash->{id}             }
    #);
    #if ($miseq_well_experiment_rs->count > 1) {
    #   print('Search returned multiple miseq well experiments for given miseq experiment id and well id');
    #   exit();
    #}
    #elsif ($miseq_well_experient_rs->count <  1){
    #   print('Search returned empty');
    #   exit();
    #}
    #else{
    #   $miseq_well_experiment_hash = $miseq_well_experiment_rs->next()->as_hash;
    #}




    #open my $fh, '<:encoding(UTF-8)', $file or die "Could not open file '$file' $!";
    #my $ov = read_data( $fh , $miseq_well_experiment_hash->{id});
    #close $fh;

    #$model->schema->txn_do( sub {
    #        try {
    #           $model->create_miseq_alleles_frequency($ov);
    #           print "Inserted frequencies for Miseq Well Experiment ID: " . $miseq_well_experiment_hash->{id} . "\n";
    #       };
    #       catch {
    #           warn "Could not create record for Miseq Well Experiment ID: " . $miseq_well_experiment_hash->{id} . "\n";
    #           $model->schema->txn_rollback;
    #       };
    #   });
}


# Sub go here

sub read_data {
    my ( $fh , $miseq_w_exp_id) = @_;
    my $counter=0;
    my $overview;
    my @words;
    my $row;

    while (my $line = $fh || $counter < 10)
    {
        chomp $line;
        next if $counter < 1;
        @words = split(/\t/, $line);
        $row =
        {
            miseq_well_experiment_id    => $miseq_w_exp_id,
            aligned_sequence            => $words[0],
            nhej                        => $words[2],
            unmodified                  => $words[3],
            hdr                         => $words[4],
            n_deleted                   => $words[5],
            n_mutated                   => $words[6],
            n_reads                     => $words[7]
        };
        $overview->{$counter} = {$row};
        #push (@{$overview{$counter}}, $row);
        $counter++;

    }
    return $overview;
}
