package LIMS2::Model::Util::RefdataUpload;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::RefdataUpload::VERSION = '0.412';
}
## use critic


use LIMS2::Model::Util::DataUpload qw(parse_csv_file);
use Log::Log4perl qw( :easy );
use LIMS2::Exception::Validation;
use Try::Tiny;
use Data::Dumper;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            load_csv_file
          )
    ]
};

sub load_csv_file {
    my ( $fh, $rs ) = @_;
    my $csv_data;

    try {
        $csv_data = parse_csv_file($fh);
    }
    catch {
        unless ($_ =~ /No data in csv file/) {
            DEBUG( "Error parsing csv file" );
            LIMS2::Exception::Validation->throw( "Invalid csv file: $_" );
        }
    };
    my $current_csv;
    my $rec_copy;
    try {
        for my $csv_record (@{$csv_data}) {
            $current_csv = $csv_record;
            my $rec = $rs->update_or_new({%{$csv_record}});
            $rec_copy = $rec;
            if ($rec->in_storage) {
                # the record was updated
            }
            else {
                # the record is not yet in the database, let's insert it
                $rec->insert;
            }
        }
    }
    catch {
        DEBUG( "Error inserting csv data ('" . $_ . "')" );
        DEBUG( "Result set - " . $rs->result_class );
        LIMS2::Exception::Validation->throw( "Result set - "  . " Rec - " . $rec_copy );
        #"Error inserting csv data: " . $_ 
    };

    return;
}

1;
__END__


