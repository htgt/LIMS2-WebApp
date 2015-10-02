package LIMS2::Model::Util::SequencingProject;
use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [qw( build_seq_data build_xlsx_file)]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception::Validation;
use LIMS2::Exception::System;
use namespace::autoclean;
use Try::Tiny;
use Excel::Writer::XLSX;
use File::Slurp;

sub build_seq_data {
    my ( $self, $c, $id) = @_;
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
            my $sample = $seq_project->{name} . '.' . $well;
            my $row = ({
                'well'          => $well,
                'sample_name'   => $sample,
                'primer_name'   => 'premix w. temp',
            });
            push @data, $row;
        }
    }
    my $geno_primers = $c->model('Golgi')->schema->resultset('SequencingProjectGenotypingPrimer')->search( { seq_project_id => $id } );

    my $crispr_primers = $c->model('Golgi')->schema->resultset('SequencingProjectCrisprPrimer')->search( { seq_project_id => $id } );

    my $data_hash = ({
        project_data => $seq_project,
        data => \@data,
    });

    my $primer;
    if ($geno_primers){
        while ($primer = $geno_primers->next){
            build_xlsx_file($self, $c, $data_hash, $primer->{_column_data}->{primer_id});
        }
    }
    if ($crispr_primers){
        while ($primer = $crispr_primers->next){
            build_xlsx_file($self, $c, $data_hash, $primer->{_column_data}->{primer_id});
        }

    }
    return;
}

sub build_xlsx_file {
    my ($self, $c, $wells, $primer_name) = @_;
    my $project = $wells->{project_data};
    my $file_name = $project->{name} . '_' . $project->{sub_projects} . '_' . $primer_name . '.xlsx';
    my $workbook = Excel::Writer::XLSX->new( '/tmp/' . $file_name );
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

    xlsx_transport($self, $c, $file_name)
}

sub xlsx_transport {
    my ($self, $c, $name) = @_;
    
    my $body = read_file( '/tmp/' . $name, {binmode => ':raw'} ) ;
    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $name
    );
    $c->response->body( $body );
    
    return;
}
1;
