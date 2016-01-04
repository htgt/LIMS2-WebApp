package LIMS2::Model::Util::SequencingProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::SequencingProject::VERSION = '0.358';
}
## use critic

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
use Carp;
use Path::Class;
use MooseX::Types::Path::Class::MoreCoercions qw/AbsDir/;
use LIMS2::Model::Util::WellName qw/to384/;

sub build_seq_data {
    my ( $self, $c, $id, $primer_req, $sub_number) = @_;
    $c->assert_user_roles('read');

    my $seq_project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->schema->resultset('SequencingProject')->find( { id => $id } )->{_column_data};
        }
    );

    #Generate data for spreedsheet
    my @data = generate_rows($seq_project, $sub_number, $primer_req, 1);

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
        $file_name = build_xlsx_file($self, $c, $data_hash, $primer_rs->{_column_data}->{primer_id}, $sub_number, $seq_project);
    }
    else {
        return "Primers not found.";
    }

    my $dir = dir_build($file_name);
    my $body = read_file( $dir, {binmode => ':raw'} );

    my $file_contents = ({
        body    => $body,
        name    => $file_name,
    });

    return $file_contents;
}

sub generate_rows {
    my ($seq_project, $sub_number, $primer_req, $recursion) = @_;
    my @well_letters = qw( A B C D E F G H );
    my @data;

    foreach my $letter (@well_letters) {
        for (my $well_number = 1; $well_number < 13; $well_number++){
            my $row;
            if ($seq_project->{is_384}){
                for (my $quad = 1; $quad < 5; $quad++){
                    $row = construct_row($letter, $well_number, $seq_project, $primer_req, $sub_number, $quad);
                    push @data, $row;
                }
            }
            else {
                $row = construct_row($letter, $well_number, $seq_project, $primer_req, $sub_number);
                push @data, $row;
            }
        }
    }
    return @data;
}

sub construct_row {
    my ($letter, $well_number, $seq_project, $primer_req, $sub_number, $quad) = @_;
    my $primer_name = 'premix w. temp';
    my $qcwell = (lc $letter) . sprintf("%02d",$well_number);
    my $well;
    my $sample;
    my $row;

    if ($seq_project->{is_384}){
        my $sample_no = $sub_number + $quad - 1;
        unless ($sample_no <= $seq_project->{sub_projects}){
            $row = ({
                'well'          => 'EMPTY',
                'sample_name'   => "",
                'primer_name'   => "",
            });
            return $row;
        }
        $well = to384('_' . $quad, $qcwell);
        $sample = $seq_project->{name} . '_' . $sample_no . $qcwell . '.p1k' . $primer_req;
    }
    else {
        $well = $letter . $well_number;
        $sample = $seq_project->{name} . '_' . $sub_number . $qcwell . '.p1k' . $primer_req;
    }
    #Lowercase letter and single digit wells include leading zero so a01, a02. Required format for qc
    #e.g. Marshmallow_1a01.p1kLR
    $row = ({
        'well'          => $well,
        'sample_name'   => $sample,
        'primer_name'   => $primer_name,
    });
    return $row;
}

sub build_xlsx_file {
    my ($self, $c, $wells, $primer_name, $sub_num, $seq_project) = @_;
    my $project = $wells->{project_data};
    my $file_name;
    if ($seq_project->{is_384}) {
        my $max = $sub_num + 3;
        if ($sub_num == $seq_project->{sub_projects}) {
            $file_name = $project->{name} . '_' . $sub_num . '_' . $primer_name . '.xlsx';
        }
        elsif ($max > $seq_project->{sub_projects}) {
            $file_name = $project->{name} . '_' . $sub_num . '-' . $seq_project->{sub_projects} . '_' . $primer_name . '.xlsx';
        }
        else {
            $file_name = $project->{name} . '_' . $sub_num . '-' . $max . '_' . $primer_name . '.xlsx';
        }
    }
    else {
        $file_name = $project->{name} . '_' . $sub_num . '_' . $primer_name . '.xlsx';
    }

    #Write file to temp loction
    my $dir = dir_build($file_name);
    my $workbook = Excel::Writer::XLSX->new($dir);

    my $worksheet = $workbook->add_worksheet();

    #Write sheet headers
    my @headers = ( 'Well','Sample name','1. Primer name','1. Primer sequence','2. Primer name','2. Primer sequence' );
    $worksheet->write_row( 'A1', \@headers );

    #Write generated data to file
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

sub dir_build {
    my ($file_name) = @_;
    my $base = $ENV{LIMS2_TEMP}
        or die "LIMS2_TEMP not set";
    return $base . '/' . $file_name;
}


1;
