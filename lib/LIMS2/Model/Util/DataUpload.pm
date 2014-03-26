package LIMS2::Model::Util::DataUpload;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            parse_csv_file
            upload_plate_dna_status
            spreadsheet_to_csv
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( none );
use LIMS2::Exception::Validation;
use Text::CSV_XS;
use IO::File;
use Try::Tiny;
use Perl6::Slurp;
use Text::Iconv;
use Spreadsheet::XLSX;
use File::Temp;

Log::Log4perl->easy_init($DEBUG);

sub pspec__check_dna_status {
    return {
        well_name         => { validate  => 'well_name' },
        dna_status_result => { validate  => 'pass_or_fail', post_filter  => 'pass_to_boolean', rename => 'pass' },
        comments          => { validated => 'non_empty_string', optional => 1, rename => 'comment_text' },
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
            _process_concentration_data($datum,$plate);
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
    my $plate_type = $input_well->plate->type_id;
    my $species = $input_well->plate->species_id;
    my $minimum;
    ## FIXME: should specify this in some config file
    if($species eq 'Human' and $plate_type eq 'FINAL_PICK'){
        $minimum = 20;
    }
    elsif($species eq 'Human' and $plate_type eq 'CRISPR_V'){
        $minimum = 30;
    }
    elsif($species eq 'Mouse' and $plate_type eq 'CRISPR_V'){
        $minimum = 40;
    }
    else{
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
    catch {
        DEBUG( sprintf( "Error parsing csv file '%s': %s", $csv->error_input || '', '' . $csv->error_diag) );
        LIMS2::Exception::Validation->throw( "Invalid csv file" . $_ );
    };
    return _clean_csv_data( $csv_data );
}

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
