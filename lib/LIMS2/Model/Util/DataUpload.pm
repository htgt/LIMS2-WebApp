package LIMS2::Model::Util::DataUpload;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::DataUpload::VERSION = '0.531';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            parse_csv_file
            upload_plate_dna_status
            upload_plate_dna_quality
            upload_plate_pcr_status
            process_het_status_file
            spreadsheet_to_csv
            csv_to_spreadsheet
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( none );
use LIMS2::Exception::Validation;
use Text::CSV_XS;
use IO::File;
use TryCatch;
use Perl6::Slurp;
use Text::Iconv;
use Spreadsheet::XLSX;
use Excel::Writer::XLSX;
use File::Temp;
use LIMS2::Model::Constants qw( %VECTOR_DNA_CONCENTRATION );
use LIMS2::Exception::System;
use File::Slurp;
use Data::Dumper;

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}

sub pspec__check_dna_status {
    return {
        well_name           => { validate => 'well_name' },
        dna_status_result   => { validate => 'pass_or_fail', post_filter  => 'pass_to_boolean', rename => 'pass' },
        concentration_ng_ul => { validate => 'signed_float', optional => 1 },
        comments            => { validate => 'non_empty_string', optional => 1, rename => 'comment_text' },
    };
}

sub upload_plate_dna_status {
    my ( $model, $params ) = @_;
    my @success_message;
    my @failure_message;

    my $data = parse_csv_file( $params->{csv_fh} );

    my $plate = $model->retrieve_plate( { name => $params->{plate_name} } );
    check_plate_type( $plate, [ qw(DNA) ]  );

    for my $datum ( @{$data} ) {
        if($params->{from_concentration}){
            # Input is from concentration measurment spreadsheet so needs
            # some additional processing
            try{
                ## This method fails if well is not defined on plate
                ## we need to allow for empty wells
                _process_concentration_data($datum,$plate);
            }
            catch ($error){
                push @failure_message, $error;
                next;
            }
        }
        my $validated_params = $model->check_params( $datum, pspec__check_dna_status() );
        my $dna_status = $model->create_well_dna_status(
            +{
                %{ $validated_params },
                plate_name => $params->{plate_name},
                created_by => $params->{user_name},
            }
        );

        if ( $dna_status ) {
            push @success_message,
                $dna_status->well->name . ' - ' . ( $dna_status->pass == 1 ? 'pass' : 'fail' );
        }
        else {
            # Some of the wells in the input were not present in LIMS2
            # This should not happen because we catch this during '_process_concentration_data' step
            push @failure_message,
                $validated_params->{'well_name'} . ' - well not available in LIMS2';
        }
    }

    push my @returned_messages, ( @failure_message, @success_message );
    return \@returned_messages;
}


sub pspec__check_pcr_status {
    return {
        well_name     => { validate => 'well_name' },
        l_pcr_result  => { validate => 'pass_or_fail' },
        l_pcr_comment => { validate => 'non_empty_string', optional => 1 },
        r_pcr_result  => { validate => 'pass_or_fail' },
        r_pcr_comment => { validate => 'non_empty_string', optional => 1 },
    };
}


# pcr status is being stored as a recombineering result, using pcr_u as left 5'-pcr and  pcr_d as right 3'-pcr
sub upload_plate_pcr_status {
    my ( $model, $params ) = @_;
    my @success_message;
    my @failure_message;

    my $data = parse_csv_file( $params->{csv_fh} );

    my $plate = $model->retrieve_plate( { name => $params->{plate_name} } );
    check_plate_type( $plate, [ qw(DESIGN) ]  );

    for my $datum ( @{$data} ) {

        # remove any whitespace and get it lowercased
        if ( !$datum->{'l_pcr_result'} || !$datum->{'r_pcr_result'} ) {
            LIMS2::Exception::Validation->throw(
                $datum->{'well_name'} . ' - l_pcr_result and r_pcr_result both required, plese check csv file'
            );
        }

        $datum->{'l_pcr_result'} = lc trim_string($datum->{'l_pcr_result'});
        $datum->{'r_pcr_result'} = lc trim_string($datum->{'r_pcr_result'});

        my $validated_params = $model->check_params( $datum, pspec__check_pcr_status() );

        my $l_pcr_status = $model->create_well_recombineering_result( {
            result_type    => 'pcr_u',
            well_name      => $validated_params->{'well_name'},
            result         => $validated_params->{'l_pcr_result'},
            comment_text   => $validated_params->{'l_pcr_comment'},
            plate_name     => $params->{plate_name},
            created_by     => $params->{user_name},
        } );

        my $r_pcr_status = $model->create_well_recombineering_result( {
            result_type    => 'pcr_d',
            well_name      => $validated_params->{'well_name'},
            result         => $validated_params->{'r_pcr_result'},
            comment_text   => $validated_params->{'r_pcr_comment'},
            plate_name     => $params->{plate_name},
            created_by     => $params->{user_name},
        } );

        if ( $l_pcr_status && $r_pcr_status ) {
            push @success_message, $l_pcr_status->well->name . " - 5'-PCR " . $l_pcr_status->result .
                ", 3'-PCR " . $r_pcr_status->result;
        } else {
            # Some of the wells in the input were not present in LIMS2
            push @failure_message, $validated_params->{'well_name'} . ' - well not available in LIMS2';
        }
    }

    push my @returned_messages, ( @failure_message, @success_message );
    return \@returned_messages;
}



sub pspec__check_dna_quality {
    return {
        well_name           => { validate => 'well_name' },
        egel_status     => { validate => 'pass_or_fail', post_filter  => 'pass_to_boolean', rename => 'egel_pass', optional => 1 },
        quality             => { validate => 'dna_quality', optional => 1 },
        comments            => { validate => 'non_empty_string', optional => 1, rename => 'comment_text' },
        REQUIRE_SOME        => { quality_or_egel_status => [ 1, qw(quality egel_status) ] },
    };
}

sub upload_plate_dna_quality {
    my ( $model, $params ) = @_;
    my @success_message;
    my @failure_message;

    my $data = parse_csv_file( $params->{csv_fh} );

    my $plate = $model->retrieve_plate( { name => $params->{plate_name} } );
    check_plate_type( $plate, [ qw(DNA ASSEMBLY) ]  );

    for my $datum ( @{$data} ) {
        my $validated_params = $model->check_params( $datum, pspec__check_dna_quality() );
        my $dna_quality = $model->update_or_create_well_dna_quality(
            +{
                %{ $validated_params },
                plate_name => $params->{plate_name},
                created_by => $params->{user_name},
            }
        );

        if ( $dna_quality) {
            if(defined $dna_quality->egel_pass){
            push @success_message,
                $dna_quality->well->name . ' - egel ' . ( $dna_quality->egel_pass == 1 ? 'pass' : 'fail' );
            }
            if(defined $dna_quality->quality){
                $dna_quality->well->name . ' - quality: ' . ( $dna_quality->quality );
            }
        }
        else {
            # Some of the wells in the input were not present in LIMS2
            push @failure_message,
                $validated_params->{'well_name'} . ' - well not available in LIMS2';
        }
    }

    push my @returned_messages, ( @failure_message, @success_message );
    return \@returned_messages;
}

sub _process_concentration_data{
    my ($datum, $plate) = @_;

    # Pad out numerical part of well name
    my $well_name = delete $datum->{Well};
    unless($well_name){
        LIMS2::Exception::Validation->throw(
            'No Well provided in DNA concentration data'
        );
    }
    my ($letter, $number) = ($well_name =~ m/^([A-Z])([0-9]*)$/g);
    my $formatted_well_name = sprintf('%s%02d', $letter, $number);
    $datum->{'well_name'} = $formatted_well_name;

    # Determine source plate type
    my ($well) = $plate->search_related('wells', {name => $formatted_well_name});
    unless($well){
        LIMS2::Exception::Validation->throw(
            "Upload contains well $formatted_well_name which was not found on plate ".$plate->name
        );
    }
    my ($input_well) = $well->ancestors->input_wells($well);
    my $plate_type = $input_well->plate_type;
    my $species = $input_well->plate_species->id;
    my $minimum;
    try{
        $minimum = $VECTOR_DNA_CONCENTRATION{$species}->{$plate_type};
    }
    unless(defined $minimum){
        LIMS2::Exception::Validation->throw(
            "No concentration threshold defined for $species $plate_type DNA"
        );
    }

    # Score as pass or fail
    my $concentration = delete $datum->{'Concentration ng/ul'};
    unless($concentration){
        LIMS2::Exception::Validation->throw(
            'No concentration value provided in DNA concentration data'
        );
    }
    $datum->{concentration_ng_ul} = $concentration;

    my $result;
    if ($concentration > $minimum ){
        $result = 'pass';
    }
    else{
        $result = 'fail';
    }
    DEBUG("concentration: $concentration, minimum: $minimum, result: $result");
    $datum->{dna_status_result} = $result;
    return;
}

sub _pspec_het_status{
    return{
        parent_plate_name => { validate => 'plate_name' },
        parent_well_name  => { validate => 'well_name' },
        well_name         => { optional => 1 },
        five_prime        => { validate => 'non_empty_string', optional => 1 },
        three_prime       => { validate => 'non_empty_string', optional => 1 },
    }
}

sub process_het_status_file{
    my ( $model, $csv_fh, $user ) = @_;

    my $data = parse_csv_file( $csv_fh );

    my @messages;
    foreach my $datum (@$data){
        DEBUG Dumper($datum);
        my $params = $model->check_params( $datum, _pspec_het_status() );

        my $well = $model->retrieve_well({
            well_name  => $params->{parent_well_name},
            plate_name => $params->{parent_plate_name},
        }) or die "Could not find well ".$params->{parent_plate_name}." ".$params->{parent_well_name};

        my $het_status = $model->set_het_status({
            well_id     => $well->id,
            five_prime  => $params->{five_prime},
            three_prime => $params->{three_prime},
            user        => $user,
        });

        push @messages, "Well $well het status: three_prime = "
                        .$het_status->three_prime.", five_prime: ".$het_status->five_prime;
    }

    return \@messages;
}

sub check_plate_type {
    my ( $plate, $types ) = @_;

    if ( none{ $plate->type_id eq $_ } @{ $types } ) {
        LIMS2::Exception::Validation->throw(
            'Invalid plate type ' . $plate->type_id . ' for plate '
            . $plate->name . ', expected plates of type(s) ' . join( ',', @{$types} )
        );
    }

    return;
}

sub spreadsheet_to_csv {
    my ( $spreadsheet ) = @_;

    my $converter = Text::Iconv->new("utf-8", "windows-1251");
    my $excel = Spreadsheet::XLSX->new($spreadsheet, $converter);
    my $csv = Text::CSV_XS->new( { eol => "\n" } );

    my %worksheets;

    foreach my $sheet (@{$excel->{Worksheet}}) {

        my $output_fh = File::Temp->new() or die "Error creating temp file - $!";
        $output_fh->unlink_on_destroy(0);

        $worksheets{ $sheet->{Name} } = $output_fh->filename;

        $sheet->{MaxRow} ||= $sheet->{MinRow};

        foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
            my @vals = map { $_->{Val} } grep{$_} @{ $sheet->{Cells}[$row] };
            $csv->print($output_fh, \@vals);
        }
    }

    return \%worksheets;
}

#Converts a CSV into XLSX format. Returns the file in raw format with file name
sub csv_to_spreadsheet {
    my ( $csv_name, $csv_fh ) = @_;
    my $csv = Text::CSV_XS->new( { binary => 1, eol => "\n" } );

    my $base = $ENV{LIMS2_TEMP}
        or die "LIMS2_TEMP not set";
    $csv_name = $csv_name . '.xlsx';
    my $dir = $base . '/' . $csv_name;
    my $workbook = Excel::Writer::XLSX->new($dir);
    my $worksheet = $workbook->add_worksheet();

    my @row;
    my $row_number = 1;
    my @body = @{$csv->getline_all($csv_fh)};
    foreach my $body_line (@body) {
        @row = @{$body_line};
        $worksheet->write_row('A' . $row_number, \@row);
        $row_number++;
    }
    $workbook->close;
    my $file = read_file( $dir, {binmode => ':raw'} );
    my $file_contents = ({
        file    => $file,
        name    => $csv_name,
    });

    return $file_contents;
}

# remove whitespace from beginning and end of string
sub trim_string {
    my $string = shift;

    $string =~ s/(^\s+|\s+$)//g;

    return $string;
}

## no critic (RequireFinalReturn)
# perlcritic started complaining this sub does not end with return after
# I switched from using Try::Tiny to TryCatch.. don't know why
sub parse_csv_file {
    my ( $fh, $optional_header_check ) = @_;
    my $cleaned_fh = _clean_newline( $fh );
    my $csv = Text::CSV_XS->new( { blank_is_undef => 1, allow_whitespace => 1 } );
    my $csv_data;

    my $column_names = $csv->getline($cleaned_fh);
    LIMS2::Exception::Validation->throw( "No data in csv file")
        if !$column_names || !@{$column_names};
    $csv->column_names( $column_names );
    $csv_data = $csv->getline_hr_all($cleaned_fh);
    LIMS2::Exception::Validation->throw( "No data in csv file")
        unless @{$csv_data};
    try {
        # Check headers
        if ($optional_header_check) {
            # get the hash for the first row
            my $header = @{$csv_data}[0];
            # get the header names in the hash (keys)
            my @keys = keys %{$header};
            # check if required headers are there, if not raise exception
            for my $header_field (@{$optional_header_check}) {
                if ( !grep { $_ =~ /^$header_field$/ } @keys ) {
                    LIMS2::Exception::Validation->throw( ", missing column \'$header_field\'" );
                }
            }
        }
    }
    catch($e){
        DEBUG( sprintf( "Error parsing csv file '%s': %s", $csv->error_input || '', '' . $csv->error_diag) );
        LIMS2::Exception::Validation->throw( "Invalid csv file" . $e );
    }
    return _clean_csv_data( $csv_data );
}
## use critic

sub _clean_newline {
    my $fh = shift;

    my $cleaned_fh = IO::File->new_tmpfile() or die("Error creating Temp File: $!");
    my @data = split /\n|\r|\r\n/, slurp( $fh );

    my $cleaned_data = join "\n", @data;
    $cleaned_fh->print($cleaned_data);
    $cleaned_fh->seek( 0, 0 );

    return $cleaned_fh;
}

sub _clean_csv_data {
    my $data = shift;

    for my $datum ( @{ $data } ) {
        #delete keys from each hash where we have no value
        my @empty_keys = grep{ not defined $datum->{$_} } keys %{ $datum };
        delete @{ $datum }{ @empty_keys };

        # delete rows with only well_name as value - may be the case if using template files with
        # well names pre-filled.
        delete $datum->{well_name}
            if scalar( keys %{ $datum } ) == 1 && exists $datum->{well_name};
    }
    #remove rows with no data
    return [ grep{ keys %{ $_ } } @{ $data } ];
}

1;

__END__
