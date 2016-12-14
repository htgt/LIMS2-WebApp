package LIMS2::WebApp::Controller::User::PointMutation;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use Data::UUID;
use File::Find;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::DesignTargets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub point_mutation : Path('/user/point_mutation') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    
    my $path = $ENV{LIMS2_RNA_SEQ} . '/build_data.json';
    
    my $json = encode_json ({ summary => generate_summary_data($c) });

    my @exps = ('A','B','C','D','E','F','G','H');

    $c->stash(
        wells => $json,
        experiments => \@exps,
    );

    return;
}

sub generate_summary_data { 
    my ( $c ) = @_;

    #Used for testing data generation
    my @genes = ('FOXA1','BRCA1','SOX9','MSC6','DEC1','UNG','ITGA6','NF1');
    my @status = ('Freezer','Freezer','Freezer','Freezer','Scanned-out','Contaminated');
    my $ug = Data::UUID->new;
    #End of

    my $wells;

    for (my $i = 1; $i < 97; $i++) {
        my $reg = "S" . $i . "_exp[ABCDEFGH]";
        my $base = $ENV{LIMS2_RNA_SEQ};
        my @files = find_children($base, $reg);
        my @exps;

        foreach my $file (@files) {
            my @matches = ($file =~ /S\d+_exp([A-H])/g);
            foreach my $match (@matches) {
                push (@exps,$match);
            }
        }
        
        @exps = sort @exps;
        my @selection;
        my $percentages;
        my @found_exps;

        foreach my $exp (@exps) {
            #Serves no purpose past dev. Used just for generating multiple genes for a well. GET RID WHEN YOU HAVE REAL DATA FOR GENES
            my $point = ord($exp) - 65;
            push (@selection, $genes[$point]);

            #Actual NHEJ data

            my $quant = find_file($base, $i, $exp);

            if ($quant) {
                my $fh;
                open ($fh, $quant) or die "$!";
                my @lines = read_file_lines($fh);
                close $fh;
                
                my @wt = ($lines[1] =~ qr/^,- Unmodified:(\d+)/);
                my @nhej = ($lines[2] =~ qr/^,- NHEJ:(\d+)/);
                my @hdr = ($lines[3] =~ qr/^,- HDR:(\d+)/);
                my @mixed = ($lines[4] =~ qr/^,- Mixed HDR-NHEJ:(\d+)/);

                $percentages->{$exp}->{nhej} = $nhej[0];
                $percentages->{$exp}->{wt} = $wt[0];
                $percentages->{$exp}->{hdr} = $hdr[0];
                $percentages->{$exp}->{mix} = $mixed[0];

                push(@found_exps, $exp); #In case of missing data
            }
        }
        
        #Genes, Barcodes and Status are randomly generated at the moment
        $wells->{sprintf("%02d", $i)} = {
            gene        => \@selection,
            experiments => \@found_exps,
            barcode     => [$ug->create_str(), $ug->create_str()],
            status      => $status[int(rand(6))],
            percentages => $percentages,
        };
    }
    return $wells;
}

sub point_mutation_allele : Path('/user/point_mutation_allele') : Args(0) {
    my ( $self, $c ) = @_;
    my $index = $c->req->param('oligoIndex');
    my $exp_sel = $c->req->param('exp');
$DB::single=1;
    my $reg = "S" . $index . "_exp[ABCDEFGH]";
    my $base = $ENV{LIMS2_RNA_SEQ};
    my @files = find_children($base, $reg);
    my @exps;

    my $well_name;
    foreach my $file (@files) {
        my @matches = ($file =~ /S\d+_exp([A-H])/g);
        foreach my $match (@matches) {
            push (@exps,$match);
        }
        my $path = $base . $file;
        my $fh;
        opendir $fh, $path; 
        $well_name = find_folder($path, $fh);
        closedir $fh;
    }
    @exps = sort @exps;
    
    $c->stash(
        oligo_index => $index,
        selection   => $exp_sel,
        experiments => \@exps,
        well_name   => $well_name,
        indel       => '1b.Indel_size_distribution_percentage.png',
    );
    
    return;
}

sub find_children {
    my ( $base, $reg ) = @_;
    my $fh;
    opendir $fh, $base;
    my @files = grep {/$reg/} readdir $fh;
    closedir $fh;
    return @files;
}

sub find_file {
    my ( $base, $index, $exp ) = @_;

    my $nhej_files = [];
    my $wanted = sub { _wanted( $nhej_files, "Quantification_of_editing_frequency.txt" ) };
    my $dir = $base . "S" . $index . "_exp" . $exp;
    find($wanted, $dir);

    return @$nhej_files[0];
}

sub find_folder {
    my ($path, $fh) = @_;
    
    my $res;
    while ( my $entry = readdir $fh ) {
        next unless -d $path . '/' . $entry;
        next if $entry eq '.' or $entry eq '..';
        my @matches = ($entry =~ /CRISPResso_on_Homo-sapiens_(\S*$)/g); #Max 1

        $res = $matches[0];
    }

    return $res;
}

sub _wanted {
    return if ! -e; 
    my ( $nhej_files, $file_name ) = @_;

    push(@$nhej_files, $File::Find::name) if $File::Find::name=~ /$file_name/;
}

sub read_file_lines {
    my ($fh) = @_;
    
    my @data;
    while (my $row = <$fh>) {
        chomp $row;
        push(@data, join(',', split(/\t/,$row)));
    }

    return @data;
}

__PACKAGE__->meta->make_immutable;

1;
