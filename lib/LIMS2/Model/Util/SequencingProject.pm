package LIMS2::Model::Util::SequencingProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::SequencingProject::VERSION = '0.493';
}
## use critic

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [qw( build_seq_data build_xlsx_file custom_sheet)]
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
    my ( $self, $c, $id, $primer_req, $sub_number, $mixFlag) = @_;
    $c->assert_user_roles('read');

    my $seq_project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->schema->resultset('SequencingProject')->find( { id => $id } )->{_column_data};
        }
    );

    #Generate data for spreedsheet

    $seq_project->{primer_flag} = $mixFlag;

    my @data = generate_rows($seq_project, $sub_number, $primer_req);

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
        $file_name = build_xlsx_file($data_hash, $primer_rs->{_column_data}->{primer_id}, $sub_number, $seq_project);
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
    my ($seq_project, $sub_number, $primer_req, $custom) = @_;
    my @well_letters = qw( A B C D E F G H );
    my @data;
    foreach my $letter (@well_letters) {
        my $custom_details;
        if ($custom) {
            $custom_details = custom_row($letter, $primer_req);
        }

        for (my $well_number = 1; $well_number < 13; $well_number++){
            my $row;
            if ($custom){
                $row = custom_well($letter, $well_number, $seq_project, $sub_number, $custom_details);
                push @data, $row;
            }
            elsif ($seq_project->{is_384}) {
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

sub custom_row {
    my ($letter,  $layout) = @_;
    my @primers = keys(%{$layout});
    my $row_details;

    foreach my $primer (@primers) {
        foreach my $row_hash (@{$layout->{$primer}}) {
            if ($row_hash->{row} eq $letter) {
                $row_details = $row_hash;
                $row_details->{primer} = $primer;
            }
        }
    }

    return $row_details;
}

sub custom_well {
    my ($letter, $well_number, $seq_project, $sub_number, $row_details) = @_;

    my $well = $letter . $well_number;
    my $row;

    if ($row_details->{primer} ne "EMPTY") {
        my $qcwell = (lc $row_details->{primer_letter}) . sprintf("%02d",$well_number);
        my $sample = $seq_project->{name} . '_' . $sub_number . $qcwell . '.p1k' . $row_details->{primer};
        if ($seq_project->{premix} == 1) {
            $row = ({
                'well'          => $well,
                'sample_name'   => $sample,
                'primer_name'   => 'premix w. temp',
            });
        } else {
            $row = ({
                'well'          => $well,
                'sample_name'   => $sample,
                'primer_name'   => $row_details->{primer},
            });
        }
    }
    else {
        $row = ({
            'well'          => 'EMPTY',
            'sample_name'   => "",
            'primer_name'   => "",
        });
    }

    return $row;
}

sub construct_row {
    my ($letter, $well_number, $seq_project, $primer_req, $sub_number, $quad) = @_;
    my $primer_name;
    if ($seq_project->{primer_flag} == 1){
        $primer_name = 'premix w. temp';
    } else {
        $primer_name = $primer_req;
    }
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
        if (ref $primer_req eq 'ARRAY') {
            $sample = $seq_project->{name} . '_' . $sample_no . $qcwell . '.p1k';
        } else {
            $sample = $seq_project->{name} . '_' . $sample_no . $qcwell . '.p1k' . $primer_req;
        }
    }
    else {
        $well = $letter . $well_number;
        if (ref $primer_req eq 'ARRAY') {
            $sample = $seq_project->{name} . '_' . $sub_number . $qcwell . '.p1k';
        } else {
            $sample = $seq_project->{name} . '_' . $sub_number . $qcwell . '.p1k' . $primer_req;
        }
    }
    #Lowercase letter and single digit wells include leading zero so a01, a02. Required format for qc
    #e.g. Marshmallow_1a01.p1kLR
    if (ref $primer_req eq 'ARRAY') {
        my @primers = @{$primer_req};
        $row = ({
            'well'          => $well,
            'sample_name'   => $sample,
            'primer_name'   => $primers[0],
            'seq'           => '',
            'second_primer' => $primers[1],
            'second_seq'    => '',
        });
    } else {
        $row = ({
            'well'          => $well,
            'sample_name'   => $sample,
            'primer_name'   => $primer_name,
            'seq'           => '',
            'second_primer' => '',
            'second_seq'    => '',
        });
    }
    return $row;
}


sub build_xlsx_file {
    my ($wells, $primer_name, $sub_num, $seq_project) = @_;
    my $file_name;
    my @data;

    if (ref $primer_name eq 'ARRAY') {
        #Custom file - multiple primers
        my $suffix = "";
        foreach my $primer (@{$primer_name}) {
            if ($suffix) {
                $suffix = $suffix . "_" . $primer;
            }
            else {
                $suffix = $primer;
            }
        }
        $file_name = $seq_project . '_' . $sub_num . '_' . $suffix . '.xlsx';
        @data = @{$wells};
    }

    else {
        my $project = $wells->{project_data};

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
        @data = @{$wells->{data}};
    }

    #Write file to temp loction
    my $dir = dir_build($file_name);
    setup_spreadsheet($dir, @data);
    return $file_name;
}

sub setup_spreadsheet {
    my ($dir, @data) = @_;

    my $workbook = Excel::Writer::XLSX->new($dir);

    my $worksheet = $workbook->add_worksheet();

    #Write sheet headers
    my @headers = ( 'Well','Sample name','1. Primer name','1. Primer sequence','2. Primer name','2. Primer sequence' );
    $worksheet->write_row( 'A1', \@headers );

    #Write generated data to file
    my $row_number = 2;
    foreach my $well (@data){
        my @row = ($well->{well}, $well->{sample_name}, $well->{primer_name}, $well->{seq}, $well->{second_primer}, $well->{second_seq});
        $worksheet->write_row('A' . $row_number, \@row);
        $row_number++;
    }
    $workbook->close;

    return;
}


sub dir_build {
    my ($file_name) = @_;
    my $base = $ENV{LIMS2_TEMP}
        or die "LIMS2_TEMP not set";
    return $base . '/' . $file_name;
}

sub custom_sheet {
    my ($wells, $name, $sub, $premix, @primers) = @_;

    my $seq_project = ({
        name    => $name,
        premix  => $premix,
    });
    my @data = generate_rows($seq_project, $sub, $wells, 1);
    my $file_name = build_xlsx_file(\@data, \@primers, $sub, $name);
    my $dir = dir_build($file_name);
    my $body = read_file( $dir, {binmode => ':raw'} );

    my $file_contents = ({
        body    => $body,
        name    => $file_name,
    });

    return $file_contents;
}

sub pair_sheet {
    my ($self, $c, $id, $sub, @primers) = @_;
    my $seq_project = $c->model( 'Golgi' )->txn_do(
        sub {
            shift->schema->resultset('SequencingProject')->find( { id => $id } )->{_column_data};
        }
    );
    $seq_project->{primer_flag} = 0;
    my @data = generate_rows($seq_project, $sub, \@primers);

    my $file_name = build_xlsx_file(\@data, \@primers, $sub, $seq_project->{name});
    my $dir = dir_build($file_name);
    my $body = read_file( $dir, {binmode => ':raw'} );

    my $file_contents = ({
        body    => $body,
        name    => $file_name,
    });

    return $file_contents;
}

1;
