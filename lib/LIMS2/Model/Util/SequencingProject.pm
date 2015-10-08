package LIMS2::Model::Util::SequencingProject;
use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [qw( build_seq_data build_xlsx_file)]
};

use Moose;
use Log::Log4perl qw( :easy );
use LIMS2::Exception::Validation;
use LIMS2::Exception::System;
use namespace::autoclean;
use Try::Tiny;
use Excel::Writer::XLSX;
use File::Slurp;

sub build_seq_data {
    my ( $self, $c, $id, $primer_req, $sub_number) = @_;
    $c->assert_user_roles('read');
    my $seq_project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->schema->resultset('SequencingProject')->find( { id => $id } )->{_column_data};
        }
    );

    my @well_letters = qw( A B C D E F G H );
    my @data;

    for (my $well_counter = 0; $well_counter < 8; $well_counter++) {
        my $letter = $well_letters[$well_counter];
        for (my $well_number = 1; $well_number < 13; $well_number++){
            my $well = $letter . $well_number;
            my $qcwell = (lc $letter) . sprintf("%02d",$well_number);
            my $sample = $seq_project->{name} . '_' . $sub_number . $qcwell . '.p1k' . $primer_req;
            my $row = ({
                'well'          => $well,
                'sample_name'   => $sample,
                'primer_name'   => 'premix w. temp',
            });
            push @data, $row;
        }
    }
    my $data_hash = ({
        project_data    => $seq_project,
        data            => \@data,
    });
    my $primer_rs = $c->model('Golgi')->schema->resultset('SequencingProjectPrimer')->find(
    {
        seq_project_id  => $id,
        primer_id       => $primer_req,
    });

    my $file_name;
    if ($primer_rs){
        $file_name = build_xlsx_file($self, $c, $data_hash, $primer_rs->{_column_data}->{primer_id}, $sub_number);
    }
    else {
        return "Primers not found.";
    }
    my $base = $ENV{ 'LIMS2_SEQ_DIR' } // '/var/tmp/seq/';
    my $body = read_file( $base . $file_name, {binmode => ':raw'} );

    my $file_contents = ({
        body    => $body,
        name    => $file_name,
    });

    return $file_contents;
}

sub build_xlsx_file {
    my ($self, $c, $wells, $primer_name, $sub_num) = @_;
    my $project = $wells->{project_data};
    my $file_name = $project->{name} . '_' . $sub_num . '_' . $primer_name . '.xlsx';

    my $base = $ENV{ 'LIMS2_SEQ_DIR' } // '/var/tmp/seq/';
    my $workbook = Excel::Writer::XLSX->new( $base . $file_name );
    my $worksheet = $workbook->add_worksheet();

    #Create Headers
    my @headers = ( 'Well','Sample name','1. Primer name','1. Primer sequence','2. Primer name','2. Primer sequence' );
    $worksheet->write_row( 'A1', \@headers );

    my @data = @{$wells->{data}};
    my $row_number = 2;
    foreach my $well (@data){
        my @row = ($well->{well}, $well->{sample_name}, $well->{primer_name});
        $worksheet->write_row('A' . $row_number, \@row);
        $row_number++;
    }
    $workbook->close;

    return $file_name;
}


1;
