package LIMS2::Model::Util::RefdataUpload;

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
    try {
        for my $csv_record (@{$csv_data}) {
            #print STDERR Data::Dumper->Dump([\$csv_record], [qw(csv_record)]);
            my $record = $rs->update_or_new({%{$csv_record}});
            #print STDERR Data::Dumper->Dump([\$record], [qw(record)]);

            if ($record->in_storage) {
                # the record was updated
            }
            else {
                # the record is not yet in the database, let's insert it
                $record->insert;
            }
        }
    }
    catch {
        DEBUG( "Error inserting csv data'" . $_ . "'" );
        print STDERR "Error inserting csv data'" . $_ . "'\n" ;
        LIMS2::Exception::Validation->throw( $_ );
    }
}

1;
__END__


