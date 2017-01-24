package LIMS2::WebApp::Controller::User::PointMutation;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use Data::UUID;
use File::Find;
use Text::CSV;

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
    
    my $miseq = $c->req->param('miseq');
    my $path = $ENV{LIMS2_RNA_SEQ} . '/build_data.json';

    my $overview = get_experiments($c, $miseq);
    my $json = encode_json ({ summary => generate_summary_data($c, $miseq, $overview) });
    my $ov_json = encode_json ({ summary => $overview });
    my $gene_keys = get_genes($c, $overview);
    my $revov = encode_json({ summary => $gene_keys });
    
    my @exps = sort keys %$overview;
    my @genes = sort keys %$gene_keys;
    $c->stash(
        wells => $json,
        experiments => \@exps,
        miseq => $miseq,
        overview => $ov_json,
        genes => \@genes,
        gene_exp => $revov,
    );

    return;
}

sub point_mutation_allele : Path('/user/point_mutation_allele') : Args(0) {
    my ( $self, $c ) = @_;
    my $index = $c->req->param('oligoIndex');
    my $exp_sel = $c->req->param('exp');
    my $miseq = $c->req->param('miseq');
    
    my $reg = "S" . $index . "_exp[A-Z]+";
    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
    my @files = find_children($base, $reg);
    my @exps;

    my $well_name;
    foreach my $file (@files) {
        my @matches = ($file =~ /S\d+_exp([A-Z]+)/g);
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
    
$DB::single=1;
    my @status = [ sort map { $_->id } $c->model('Golgi')->schema->resultset('MiseqStatus')->all ];
    my $states = encode_json({ summary => @status });
    $c->stash(
        miseq       => $miseq,
        oligo_index => $index,
        selection   => $exp_sel,
        experiments => \@exps,
        well_name   => $well_name,
        indel       => '1b.Indel_size_distribution_percentage.png',
        status      => $states,
        state       => 'Contaminated',
    );
    
    return;
}

sub browse_point_mutation : Path('/user/browse_point_mutation') : Args(0) {
    my ( $self, $c ) = @_;
    
    my @miseqs = sort { $b->{date} cmp $a->{date} } map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqProject')->search( { }, { rows => 15 } );
    $c->stash(
        miseqs => \@miseqs,
    );

    return;
}


sub create_point_mutation : Path('/user/create_point_mutation') : Args(0) {
    my ( $self, $c ) = @_;

$DB::single=1;
    my $name = $c->req->param('miseqName');

    if ($name) {
        #csv
        my $file = $c->request->upload('csvUpload');
        my $bp = 1;
    }

    return;
}

sub get_genes {
    my ( $c, $ow) = @_;
    
    my $genes;
    foreach my $key (keys %$ow) {
        my @exps;
        foreach my $value (@{$ow->{$key}}) {
            my @gene = ($value =~ qr/^([A-Za-z0-9\-]*)/);
            push (@{$genes->{$gene[0]}}, $key);
        }
    }

    return $genes;
}

sub get_experiments {
    my ( $c, $miseq ) = @_;

    my $csv = Text::CSV->new({ binary => 1 }) or die "Can't use CSV: " . Text::CSV->error_diag();
    my $loc = $ENV{LIMS2_RNA_SEQ} . $miseq . '/summary.csv';

    open my $fh, $loc or die "Can't open CSV: $!";
    my $ov = read_columns($c, $csv, $fh);
    close $fh;
    
    return $ov;
}

sub read_columns {
    my ( $c, $csv, $fh ) = @_;
    
    my $overview;

    while ( my $row = $csv->getline($fh)) {
        next if $. < 2;
        my @genes;
        push @genes, $row->[1];
        $overview->{$row->[0]} = \@genes;
    }

    return $overview;
}

sub generate_summary_data { 
    my ( $c, $miseq, $overview ) = @_;

    my $wells;

    for (my $i = 1; $i < 97; $i++) {
        my $reg = "S" . $i . "_exp[A-Z]+";
        my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
        my @files = find_children($base, $reg);
        my @exps;
        foreach my $file (@files) {
            my @matches = ($file =~ /S\d+_exp([A-Z]+)/g);
            foreach my $match (@matches) {
                push (@exps,$match);
            }
        }
        
        @exps = sort @exps;
        my @selection;
        my $percentages;
        my @found_exps;

        foreach my $exp (@exps) {
            foreach my $gene ($overview->{$exp}) {
                push (@selection, $gene);
            }

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
        #status

 
        #Genes, Barcodes and Status are randomly generated at the moment
        $wells->{sprintf("%02d", $i)} = {
            gene        => \@selection,
            experiments => \@found_exps,
            #barcode     => [$ug->create_str(), $ug->create_str()],
            #status      => $status[int(rand(6))],
            percentages => $percentages,
        };
    }
    return $wells;
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
    my ( $path, $fh ) = @_;
    
    my $res;
    while ( my $entry = readdir $fh ) {
        next unless -d $path . '/' . $entry;
        next if $entry eq '.' or $entry eq '..';
        #my @matches = ($entry =~ /CRISPResso_on_Homo-sapiens_(\S*$)/g); #Max 1

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
    my ( $fh ) = @_;
    
    my @data;
    while (my $row = <$fh>) {
        chomp $row;
        push(@data, join(',', split(/\t/,$row)));
    }

    return @data;
}

__PACKAGE__->meta->make_immutable;

1;
