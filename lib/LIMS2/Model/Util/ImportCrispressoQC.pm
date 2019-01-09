package LIMS2::Model::Util::ImportCrispressoQC;

use strict;
use warnings FATAL => 'all';
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Moose;
use LIMS2::Model::Util::Miseq qw( miseq_well_processes convert_index_to_well_name );
use List::Compare::Functional qw( get_intersection );
use Sub::Exporter -setup => {
    exports => [
        qw(
            get_data
            get_data_from_file
            extract_data_from_path 
            migrate_quant_file 
            update_miseq_exp
            migrate_images
            migrate_frequencies
            get_crispr
            migrate_histogram
            migrate_crispresso_subs
        )
    ],
};


#SUBS GO HERE
sub header_hash {
    my ( $header, @expected_titles ) = @_;

    my @titles = split( /\t/, lc $header );
    my @intersection = get_intersection( [ \@titles, \@expected_titles ] );
    my %head;
    %head = map { lc $titles[$_] => $_ }
        0 .. $#titles;    #creates a hash that has all the elements of the array as keys and their index as values

#check if the length of the intersection of the full array of titles is equal to the length of the array of expected titles
#This checks that all the requested elements were found within the header of the file
    if (scalar(@intersection) == scalar(@expected_titles)) {
        return %head;
    }
    else {
        warn "Miseq Alleles Frequency file does not hold all the required headers";
        return;
    }
    return 1;
}

sub migrate_crispresso_subs {
    my ( $model, $jobout, $data ) = @_;
    my $job = get_crispr($jobout);
    my $row = {
            id  =>   $data->{miseq_well_experiment}->{id},
            crispr  =>  $job ->{crispr},
            date_stamp  =>  $job->{date}
        };
    
    my $check_rs = $model->schema->resultset('CrispressoSubmission')->search( { id => $data->{miseq_well_experiment}->{id} } );
    if ( $check_rs->count >= 1 ) {
        print("Skipped. Job submission has already been loaded. \n");
        for (sort keys %$row) {
            print "$_ => $row->{$_}\n";
        }
        print "\n";
    }
    else {
        $model->schema->txn_do(
            sub {
                try {
                    $model->create_crispr_submission($row);
                }
                catch {
                    warn "Error creating cripr submission entry";
                    $model->schema->txn_rollback;
                };
            }
        );
    }
    return 1;
}

sub migrate_frequencies {
    my ( $model, $frequency_paths, $miseq_well_experiment_hash ) = @_;
    my $limit = 10;
    my $counter = 0;#counts the number of frequencies within one file
    open( my $file_to_read, "<", "$frequency_paths" ) or die "Cannot open frequency file";
    chomp(my @lines = <$file_to_read>);
    close $file_to_read or die "Cannot close frequency file";

    my $header = shift(@lines);    #grab the header line that holds the titles of the columns

    my @expected_titles
        = ( 'aligned_sequence', 'nhej', 'unmodified', 'hdr', 'n_deleted', 'n_inserted', 'n_mutated', '#reads' );
    my %head = header_hash( $header, @expected_titles );
    if (%head) {
        while (@lines) {
            my $line = shift @lines;
            if ( $counter < $limit ) {
                $counter++;
                my @words = split( /\t/, $line );    #split the space seperated values and store them in a hash
                my $row = {
                    miseq_well_experiment_id => $miseq_well_experiment_hash->{id},
                    aligned_sequence         => $words[ $head{aligned_sequence} ],
                    nhej                     => lc $words[ $head{nhej} ],
                    unmodified               => lc $words[ $head{unmodified} ],
                    hdr                      => lc $words[ $head{hdr} ],
                    n_deleted                => int $words[ $head{n_deleted} ],
                    n_inserted               => int $words[ $head{n_inserted} ],
                    n_mutated                => int $words[ $head{n_mutated} ],
                    n_reads                  => int $words[ $head{'#reads'} ],
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
            else {
                last;
            }#to escape the while after getting 10 lines of frequencies
        }
    }
    else {
        warn "File: $frequency_paths is corrupt. Could not extract titles properly";
    }
    return;
}


sub migrate_histogram {
    my ( $model, $path, $miseq_well_exp, $alleles_path ) = @_;

    my %histogram;

    if (-e $path) {
        open( my $file_to_read, "<", "$path" ) or die "Cannot open histogram file";
        chomp(my @lines = <$file_to_read>);
        close $file_to_read or die "Cannot close histogram file";
        shift @lines;
        while (@lines) {
            my $line = shift @lines;
            my ($key, $val) = split /\s+/, $line;
            if ($val and $key) {
                $histogram{$key} = $val;
            }
        }
    }
    else {
        open( my $fh, "<", "$alleles_path" ) or die "Cannot open frequency file";
        chomp(my @alleles = <$fh>);
        close $fh or die "Cannot close frequency file";
        my $header = shift(@alleles);    #grab the header line that holds the titles of the columns
        my @expected_titles = ( 'aligned_sequence', 'nhej', 'unmodified', 'hdr', 'n_deleted', 'n_inserted', 'n_mutated', '#reads' );
        my %head = header_hash( $header, @expected_titles );

        while (@alleles) {
            my $line = shift @alleles;
            my @elements = split /\s+/, $line;
            my $indel = $elements[$head{n_inserted}] - $elements[$head{n_deleted}];
            if ($indel) {
                $histogram{$indel}++;
            }
        }
    }
    my $check_rs = $model->schema->resultset('IndelHistogram')->search( { miseq_well_experiment_id => $miseq_well_exp->{id} } );
    if ( $check_rs->count >= 1 ) {
        print("Skipped. Indel histogram already has data loaded for miseq well experiment: $miseq_well_exp->{id}. \n");
    }
    else {
        foreach my $key (keys %histogram) {
            my $row = {
                miseq_well_experiment_id    =>  $miseq_well_exp->{id},
                indel_size                  =>  $key,
                frequency                   =>  $histogram{$key},
            };
            $model->schema->txn_do(
                sub {
                    try {
                        $model->create_indel_histogram($row);
                    }
                    catch {
                        warn "Error creating indel histogram entry";
                        $model->schema->txn_rollback;
                    };
                }
            );
        }
    }
    return 1;
}



#THIS SUB LOADS THE IMAGE FILES INTO THE DATABASE AS BYTEA FORMAT
#IT IS NOT USED AT THE MOMENT BECAUSE THE IMAGES WERE REPLACED BY REAL TIME PLOTTING
sub migrate_images {
    my ( $model, $image_path, $miseq_well_experiment_hash ) = @_;

    my $contents = q{};
    open( my $in_fh, "<", $image_path ) or die "Failed to open image file!";
    binmode $in_fh;

    while ( read $in_fh, my $buf, 16384 ) {
        $contents .= $buf;
    }
    close $in_fh or die "Failed to close image file!";

    my $row = {
        id                            => $miseq_well_experiment_hash->{id},
        indel_size_distribution_graph => $contents
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
        }
    );
    return 1;
}

sub update_miseq_exp {
    my ( $model, $params ) = @_;
    my $update;
    $model->schema->txn_do(
        sub {
            try {
                $update = $model->update_miseq_experiment($params);
            }
            catch {
                warn "Error creating entry";
                $model->schema->txn_rollback;
            };
        }
    );
    return $update;
}

sub migrate_quant_file {
    my ( $model, $directory, $miseq_well_experiment_hash ) = @_;

    open( my $quant_fh, '<:encoding(UTF-8)', $directory ) or die "Failed to open quant file";
    chomp(my @lines = <$quant_fh>);
    close $quant_fh or die "Cannot close frequency file";

    my %params;
    my %commands = (
        'NHEJ'           => 'nhej_reads',
        'HDR'            => 'hdr_reads',
        'Mixed HDR-NHEJ' => 'mixed_reads',
        'Total Aligned'  => 'total_reads',
    );

    while ( @lines) {
        my $line =  shift @lines;
        my ( $type, $number ) = $line =~ m/^[\s\-]* #ignore whitespace, dashes at start of line
            ([\w\-\s]+) #then grab the type e.g. "HDR", "Mixed HDR-NHEJ", etc
            :(\d+) #finally the number of reads
            /xms;
        next unless $type && $number;
        if ( exists $commands{$type} ) {
            $params{ $commands{$type} } = $number;
        }
    }

    #params hash holds the info that need to be passed to the plugin
    #miseq_experiment_hash the location it should be placed in
    my $row = {
        id              => $miseq_well_experiment_hash->{id},
        miseq_exp_id    => $miseq_well_experiment_hash->{miseq_exp_id},
        classification  => $miseq_well_experiment_hash->{classification},
        frameshifted    => $miseq_well_experiment_hash->{frameshifted},
        status          => $miseq_well_experiment_hash->{status},
        well_id         => $miseq_well_experiment_hash->{well_id},
        nhej_reads      => $params{nhej_reads},
        total_reads     => $params{total_reads},
        hdr_reads       => $params{hdr_reads},
        mixed_reads     => $params{mixed_reads},
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
        }
    );
    return %params;
}

sub frameshift_check {
    my (@common_read) = @_;

    my $fs_check = 0;
    unless ( $common_read[1] ) { $common_read[1] = 0; }
    if ( $common_read[1] eq 'True' ) {
        $fs_check = ( $common_read[4] + $common_read[5] ) % 3;
    }
    return $fs_check;
}

sub create_miseq_well_exp {
    my ( $model, $file, $well_hash, $miseq_experiment_hash ) = @_;

    my $classification = "Not Called";
    my $frameshifted   = 0;
    open( my $my_file, "<", "$file" ) or die "Cannot open file";
    chomp(my @lines = <$my_file>);
    close $my_file;

    my $head = shift @lines;

    my $most_common_line = shift @lines;
    $most_common_line = "0" unless $most_common_line;

    my $second_most_common_line = shift @lines;
    $second_most_common_line = "0" unless $second_most_common_line;

    my $mixed_read_line = shift @lines;
    $mixed_read_line = "0" unless $mixed_read_line;

    my @mixed_read = split( /\t/, $mixed_read_line );
    my $mixed_check = $mixed_read[-1];
    if ( $mixed_check >= 5 ) {
        $frameshifted   = 0;
        $classification = 'Mixed';
    }
    else {
        my @first_most_common  = split( /\t/, $most_common_line );
        my @second_most_common = split( /\t/, $second_most_common_line );
        my $fs_check = frameshift_check(@first_most_common) + frameshift_check(@second_most_common);
        if ( $fs_check != 0 ) {
            $classification = 'Not Called';
            $frameshifted   = 1;
        }
    }

    my $creation_params = {
        well_id        => $well_hash->{id},
        miseq_exp_id   => $miseq_experiment_hash->{id},
        classification => $classification,
        frameshifted   => $frameshifted,
        status         => "Plated",
        total_reads    => "0"
    };
    my $miseq;
    $model->schema->txn_do(
        sub {
            try {
                $miseq = $model->create_miseq_well_experiment($creation_params)->as_hash;
                print "Created file at: $file";
            }
            catch {
                warn "Error creating entry";
                $model->schema->txn_rollback;
            };
        }
    );
    return $miseq;
}


sub get_plate {
    my ( $model, $miseq ) = @_;

    my $plate_rs = $model->schema->resultset('Plate')->search( { name => "Miseq_" . $miseq } );
    my $plate_hash;
    my $plate;
    if ( $plate_rs->count > 1 ) {
        print("Search returned multiple plates for given id \n");
        return 0;

    }
    elsif ( $plate_rs->count < 1 ) {
        print("Search returned empty \n");
        return 0;

    }

    else {
        $plate = $plate_rs->first;
    }
    return $plate;
}

sub get_well {
    my ( $model, $well, $plate_hash ) = @_;

    #Plate id to well name gives well
    my $well_hash;
    my $well_name = convert_index_to_well_name($well);
    my $well_rs   = $model->schema->resultset('Well')->search(
        {   -and => [
                'plate_id' => $plate_hash->{id},
                'name'     => $well_name
            ]
        }
    );

    if ( $well_rs->count > 1 ) {

        print("Search returned multiple wells for given plate id and well name \n");
        return 0;

    }
    elsif ( $well_rs->count < 1 ) {
        print("Search returned empty \n");
        return 0;

    }
    else {
        $well_hash = $well_rs->first->as_hash;
    }
    return $well_hash;
}

sub get_miseq_experiment {
    my ( $model, $exp, $miseq_plate_hash ) = @_;

    #Query miseq experiment for name(extracted from the path and converted) and plate id
    my $miseq_experiment_hash;
    my $miseq_experiment_rs = $model->schema->resultset('MiseqExperiment')->search(
        {   -and => [
                'miseq_id' => $miseq_plate_hash->{id},
                'name'     => $exp
            ]
        }
    );
    if ( $miseq_experiment_rs->count > 1 ) {
        print("Search returned multiple miseq experiments for given miseq id and experiment name \n");
        return 0;

    }
    elsif ( $miseq_experiment_rs->count < 1 ) {
        print("Search returned empty \n");
        return 0;

    }
    else {
        $miseq_experiment_hash = $miseq_experiment_rs->first()->as_hash;
    }
    return $miseq_experiment_hash;
}

sub get_miseq_well_experiment {
    my ( $model, $miseq_experiment_hash, $well_hash ) = @_;
    #Query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.
    my $miseq_well_experiment_hash;
    my $miseq_well_experiment_rs = $model->schema->resultset('MiseqWellExperiment')->search(
        {   -and => [
                'miseq_exp_id' => $miseq_experiment_hash->{id},
                'well_id'      => $well_hash->{id}
            ]
        }
    );

    if ( $miseq_well_experiment_rs->count > 1 ) {
        print("Search returned multiple miseq well experiments for given miseq experiment id and well id \n");
    }
    elsif ( $miseq_well_experiment_rs->count < 1 ) {
        print("Search returned empty \n");
        return 0;
    }
    $miseq_well_experiment_hash = $miseq_well_experiment_rs->first->as_hash;
    return $miseq_well_experiment_hash;
}

sub extract_data_from_path {
    my ( $file ) = @_;

    my ( $miseq, $well, $exp ) = $file =~ m/
        Miseq_(\w+) #miseq plate number
        \/S(\d+)    #well name integer, before convert to "A01" format
        _exp(\w+)   #experiment name as string in the format "AS_EWE_E"
        /xgms;

    return 0 unless $miseq && $well && $exp;
    return {
        miseq           =>  $miseq,
        well            =>  $well,
        experiment      =>  $exp,
    }
}

sub get_data_from_file {
    my ( $model, $file ) = @_;
    my $extracted = extract_data_from_path($file);
    my $plate;
    my $plate_hash;
    my $miseq_plate_hash;
    my $well_hash;
    my $miseq_experiment_hash;
    my $miseq_well_experiment_hash;
    my $hash;

    try{

        #First get the plate hash
        $plate = get_plate( $model, $extracted->{miseq} );
        $plate_hash = $plate->as_hash;

        #Then get the miseq plate id

        $miseq_plate_hash = $plate->miseq_details;

        #Plate id to well name gives well
        $well_hash = get_well( $model, $extracted->{well}, $plate_hash );

        #Query miseq experiment for name(extracted from the path and converted) and plate id
        $miseq_experiment_hash = get_miseq_experiment( $model, $extracted->{experiment}, $miseq_plate_hash );

        #Finally, query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.

        $miseq_well_experiment_hash = get_miseq_well_experiment( $model, $miseq_experiment_hash, $well_hash );

        $miseq_well_experiment_hash = create_miseq_well_exp( $model, $file, $well_hash, $miseq_experiment_hash ) unless $miseq_well_experiment_hash;


        $hash = {
            plate                   =>  $plate_hash,
            miseq_plate             =>  $miseq_plate_hash,
            well                    =>  $well_hash,
            miseq_experiment        =>  $miseq_experiment_hash,
            miseq_well_experiment   =>  $miseq_well_experiment_hash,
        };
    }
    catch{
        warn "Corrupt Data";
    };
    return $hash;
}

sub get_data{
    my ( $model, $miseq, $well, $exp ) = @_;
    if ($miseq =~ m/Miseq_(\w+) #miseq plate pure number/xgms ) {
        $miseq = $1;
    }
    my $plate;
    my $plate_hash;
    my $miseq_plate_hash;
    my $well_hash;
    my $miseq_experiment_hash;
    my $miseq_well_experiment_hash;
    my $hash;

    try{
        #First get the plate hash
        $plate = get_plate( $model, $miseq );
        $plate_hash = $plate->as_hash;

        #Then get the miseq plate id
        $miseq_plate_hash = $plate->miseq_details;

        #Plate id to well name gives well
        $well_hash = get_well( $model, $well, $plate_hash );

        #Query miseq experiment for name(extracted from the path and converted) and plate id
        $miseq_experiment_hash = get_miseq_experiment( $model, $exp, $miseq_plate_hash );

        #Finally, query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.
        $miseq_well_experiment_hash = get_miseq_well_experiment( $model, $miseq_experiment_hash, $well_hash );

        $hash = {
            miseq_experiment      => $miseq_experiment_hash,
            miseq_well_experiment => $miseq_well_experiment_hash,
        };
    }
    catch{
        warn "Corrupt Data \n ";
    };
    return $hash;
}

sub get_crispr{
    my $file = shift;

    open( my $jobout_fh, '<:encoding(UTF-8)', $file ) or die "Failed to open file at $file";
    chomp(my @lines= <$jobout_fh>);
    close $jobout_fh;

    my $crispr;
    my $date;

    while (@lines) {
    my $line = shift @lines;
        if (!$crispr) {
            if ($line =~ m/-g\ (\w+)/xgms) {
                $crispr = $1;
            }
        }
        if (!$date) {
            if ($line =~ m/Started\ at\ (.+$)/xgms) {
                $date = $1;
            }
        }
        last if $crispr and $date;
    }
    my $hash = {
        date => $date,
        crispr => $crispr
    };
    return $hash;
}

1;

__END__

=pod           

=head1 NAME

Migration

=head1 DESCRIPTION

This library holds subs relavant to reading MiSeq Crispresso format files and loading their data into the LIMS2 database. E<10> E<8>

=head1 METHODS


=over 12

=item C<extract_data_from_path> 

Takes a file path as parameter. E<10> E<8>
Returns a hash reference holding the miseq run name, well name, and experiment name.

=item C<get_data_from_file> 

Takes the model and the file path. E<10> E<8>
Returns a reference to miseq experiment hash and  miseq well experiment hash.

=item C<get_data> 

Takes the model, the miseq run name, the well name and the experiment name. E<10> E<8>
Returns a reference to miseq experiment hash and  miseq well experiment hash.


=item C<get_miseq_well_experiment> 

Takes the model, the alleles frequency table txt file path, the $miseq_experiment_hash and the $well_hash  as paramateres. E<10> E<8>
If there is no miseq_well_experiment returned from querying miseq well experiment for miseq experiment id and well id, one is created. E<10> E<8>
Returns a reference hash.

=item C<get_miseq_experiment> 

Takes the model, experiment name, miseq plate hash, searches the miseq experient table for experiment and miseq plate id and returns a reference to a miseq experiment hash.

=item C<get_well> 

Takes the model, well, and plate hash, searches the well table for well and and plate id and returns a reference to a well hash.

=item C<get_plate>

Takes model, miseq number, as extracted from the path, and return a B<I<dataset>> that holds the information of the plate. 

=item C<create_miseq_well_exp> 

Takes model, file path to the alleles frequency txt, well hash and miseq experiment hash. E<10> E<8>
Creates a miseq well experiment according to the parameters and then returns it as a refernce hash. E<10> E<8>
NOTE: Does not check first if there is a miseq well experiment for the passed parameters before creating a new one.

=item C<frameshift_check> 

Takes in a read, as an array, performs a frameshift check and returns the outcome.

=item C<migrate_quant_file> 

Takes in model, directory, miseq experiment hash and parses it to update the miseq well experiment. 
Returns the total number of reads.

=item C<update_miseq_well_exp> 

Takes in model, miseq well experiment hash, total number of reads and updates the miseq well experiment

=item C<migrate_images> 

Takes in the model, png local path, miseq well experiment hash and creates a new entry to the appropriate database table. 

=item C<migrate_frequencies> 

Takes in model, alleles frequency txt file path and miseq_well_experiment_hash and creates an entry in the alleles frequency table foreach of the first 10 entries. 

=item C<header_hash>

Takes a string and an array of expected values.  E<10> E<8>
Splits the string to an array. E<10> E<8>
All shared elelents between the arrays are stored in a hash as keys, with their index position within the original string as the respective value. E<10> E<8>
Returns the hash if all the elements of the expected values where found within the string. E<10> E<8>
NOTE: Does not check for duplicate entries, so it will have to be updated in the future.

=back

=head1 INPUT FORMAT

=head2 Paths file
Most subs require a path string as a parameter. That path refers to the local file system.Specificaly the files examineda can be one of the follwowing:
=head2 Quantification Files

Requires a .txt file. E<10> E<8>
Example: E<10> E<8>
" E<10> E<8>
Quantification of editing frequency: E<10> E<8>
- Unmodified:1898 reads E<10> E<8>
- NHEJ:1847 reads (9 reads with insertions, 1674 reads with deletions, 1831 reads with substitutions) E<10> E<8>
- HDR:3 reads (0 reads with insertions, 1 reads with deletions, 3 reads with substitutions) E<10> E<8>
- Mixed HDR-NHEJ:4 reads (1 reads with insertions, 4 reads with deletions, 4 reads with substitutions) E<10>
 Total Aligned:3752 reads E<10> E<8>
"

=head2 Alleles frequencies

Requires a .txt file. E<10> E<8>
Example: E<10> E<8>
" E<10> E<8>
Aligned_Sequence	Reference_Sequence	NHEJ	UNMODIFIED	HDR	n_deleted	n_inserted	n_mutated	#Reads	%Reads E<10> E<8>
CCTAGAGAGCCAGGGCTAA GGTGGGTCCGTGGGCCTA	False	True	False	0.0	0.0	0	883	23.3969263381 E<10> E<8>
CCTAGAGAGCCAGGGCTAA GGTGGGTCCGTGGGCCTA	False	True	False	0.0	0.0	0	883	23.3969263381 E<10> E<8>
"

=head2 Images

Requires a .png file.

=head1 COMMON ISSUES

=head2 Paths Formatting

Highly relient of proper formatting of the path passed, since it is used to extract miseq id, experiment name and well index.

=cut
