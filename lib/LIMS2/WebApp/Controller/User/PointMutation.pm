package LIMS2::WebApp::Controller::User::PointMutation;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::PointMutation::VERSION = '0.460';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use Data::UUID;
use File::Find;
use Text::CSV;
use Try::Tiny;
use POSIX qw/floor/;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::PointMutation - Catalyst Controller

=head1 DESCRIPTION

Miseq QC Controller.

=cut



sub point_mutation : Path('/user/point_mutation') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $miseq = $c->req->param('miseq');

    my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;
    if ($plate->{'384'} == 1 ) {
        my $quadrants = experiment_384_distribution($c,$miseq);
        $c->stash->{quadrants} = encode_json({ summary => $quadrants });
    }
    my $overview = get_experiments($c, $miseq, 'genes');
    my $ov_json = encode_json ({ summary => $overview });
    my $json = encode_json ({ summary => generate_summary_data($c, $miseq, $overview) });
    my $gene_keys = get_genes($c, $overview);
    my $revov = encode_json({ summary => $gene_keys });
    my @exps = sort keys %$overview;
    my @genes = sort keys %$gene_keys;
    my $efficiencies = encode_json ({ summary => get_efficiencies($c, $miseq) });

    $c->stash(
        wells => $json,
        experiments => \@exps,
        miseq => $miseq,
        overview => $ov_json,
        genes => \@genes,
        gene_exp => $revov,
        efficiency => $efficiencies,
        large_plate => $plate->{'384'},
    );

    return;
}

sub experiment_384_distribution {
    my ( $c, $miseq ) = @_;

    my $range_summary = get_experiments($c, $miseq, 'range');
    my $quadrants;

    foreach my $exp (keys %$range_summary) {
        my $value = $range_summary->{$exp};

        my @ranges = split(/\|/,$value);
        foreach my $range (@ranges) {
            my @pos = split(/-/, $range);
            my @mods = map {floor(($_ - 1) / 96)} @pos;
            my $region = {
                'first' => $mods[0],
                'last'  => $mods[1],
            };
            push(@{$quadrants->{$exp}}, $region);
        }
    }

    return $quadrants;
}

sub point_mutation_allele : Path('/user/point_mutation_allele') : Args(0) {
    my ( $self, $c ) = @_;

    my $index = $c->req->param('oligoIndex');
    my $exp_sel = $c->req->param('exp');
    my $miseq = $c->req->param('miseq');
    my $updated_status = $c->req->param('statusOption');
    check_class($self, $c, $miseq, $index);
    if ($updated_status) {
        update_status($self, $c, $miseq, $index, $updated_status);
    }

    my $reg = "S" . $index . "_exp[A-Z]+";
    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
    my @files = find_children($base, $reg);
    my @exps;

    my $well_name;
    foreach my $file (@files) {
        my @matches = ($file =~ /S\d+_exp([A-Z]+)/g);
        foreach my $match (@matches) {
            my $class = find_classes($c, $miseq, $index, $match);
            my $rs = {
                id      => $match,
                class   => $class,
            };
            push (@exps, $rs);
        }
        my $path = $base . $file;
        my $fh;
        opendir $fh, $path;
        $well_name = find_folder($path, $fh);
        closedir $fh;
    }
    my $selection;
    if ($exp_sel) {
        my $class = find_classes($c, $miseq, $index, $exp_sel);
        my $overview = get_experiments($c, $miseq, "genes")->{$exp_sel}[0];
        $selection = {
            id      => $exp_sel,
            class   => $class,
            gene    => $overview,
        };
    }

    @exps = sort { $a->{id} cmp $b->{id} } @exps;

    my @status = [ sort map { $_->id } $c->model('Golgi')->schema->resultset('MiseqStatus')->all ];
    my $states = encode_json({ summary => @status });
    my $state;
    try {
        my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;
        $state = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $index });
        if ($state) {
            $state = $state->as_hash->{status};
        } else {
            $state = 'Plated';
        }
    } catch {
        $state = 'Plated';
    };

    my @classifications = map { $_->id } $c->model('Golgi')->schema->resultset('MiseqClassification')->all;
    $c->stash(
        miseq       => $miseq,
        oligo_index => $index,
        selection   => $selection,
        experiments => \@exps,
        well_name   => $well_name,
        indel       => '1b.Indel_size_distribution_percentage.png',
        status      => $states,
        state       => $state,
        classifications => \@classifications,
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
    my ( $c, $miseq, $opt ) = @_;

    my $csv = Text::CSV->new({ binary => 1 }) or die "Can't use CSV: " . Text::CSV->error_diag();
    my $loc = $ENV{LIMS2_RNA_SEQ} . $miseq . '/summary.csv';
    open my $fh, '<:encoding(UTF-8)', $loc or die "Can't open CSV: $!";
    my $ov = read_columns($c, $csv, $fh, $opt);
    close $fh;

    return $ov;
}

sub read_columns {
    my ( $c, $csv, $fh, $opt ) = @_;

    my $overview;

    while ( my $row = $csv->getline($fh)) {
        next if $. < 2;
        if ($opt eq 'range') {
            my $range = $row->[5];
            $overview->{$row->[0]} = $range;
        } else {
            my @genes;
            push @genes, $row->[1];
            $overview->{$row->[0]} = \@genes;
        }
    }

    return $overview;
}

sub generate_summary_data {
    my ( $c, $miseq, $overview ) = @_;

    my $wells;
    my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;

    for (my $i = 1; $i < 385; $i++) {
        my $reg = "S" . $i . "_exp[A-Z0-9]+";
        my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
        my @files = find_children($base, $reg);
        my @exps;
        foreach my $file (@files) {
            #Get all experiments on this well
            my @matches = ($file =~ /S$i\_exp([A-Z0-9]+)/g);
            foreach my $match (@matches) {
                push (@exps,$match);
            }
        }

        @exps = sort @exps;
        my @selection;
        my $percentages;
        my @found_exps;
        my $classes;

        foreach my $exp (@exps) {
            foreach my $gene ($overview->{$exp}) {
                push (@selection, $gene);
            }

            my $quant = find_file($base, $i, $exp);

            if ($quant) {
                my $fh;
                open ($fh, '<:encoding(UTF-8)', $quant) or die "$!";
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

            my $class = find_classes($c, $miseq, $i, $exp);
            $class = $class ? $class : 'Not called';
            $classes->{$exp} = $class;
        }
        #status
        my $state = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $i });
        if ($state) {
            $state = $state->as_hash->{status};
        } else {
            $state = 'Plated';
        }


        #Genes, Barcodes and Status are randomly generated at the moment
        $wells->{sprintf("%02d", $i)} = {
            gene        => \@selection,
            experiments => \@found_exps,
            #barcode     => [$ug->create_str(), $ug->create_str()],
            status      => $state,
            percentages => $percentages,
            classes     => $classes,
        };
    }
    return $wells;
}


sub find_children {
    my ( $base, $reg ) = @_;
    my $fh;
    opendir ($fh, $base);
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
        next unless $path . '/' . $entry;
        next if $entry eq '.' or $entry eq '..';
        my @matches = ($entry =~ /CRISPResso_on\S*_(S\S*$)/g); #Max 1

        $res = $matches[0];
    }

    return $res;
}

sub _wanted {
    return if ! -e;
    my ( $nhej_files, $file_name ) = @_;

    push(@$nhej_files, $File::Find::name) if $File::Find::name=~ /$file_name/;

    return;
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

sub update_status {
    my ($self, $c, $miseq, $index, $status) = @_;

    my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;
    unless ($plate) {
        return;
    }

    my $well_details = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $index });
    my $params;
    if ($well_details) {
        if ($well_details->as_hash->{status} eq $status) {
            return;
        }
        $params = {
            id      => $well_details->as_hash->{id},
            status  => $status,
        };
        $c->model('Golgi')->update_miseq_plate_well( $params );
    }
    else {
        $params = {
            miseq_plate_id  => $plate->{id},
            illumina_index  => $index,
            status          => $status,
        };
        $c->model('Golgi')->create_miseq_plate_well( $params );
    }
    return;
}


sub check_class {
    my ($self, $c, $miseq, $index) = @_;

    my $params = $c->req->params;
    my $result;

    foreach my $key (keys %$params) {
        my @matches = ($key =~ /^class([A-Z]+)$/g);
        if (@matches) {
            $result = $matches[0];
        }
    }

    if ($result) {
        my $class = $c->req->param('class' . $result);

        my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;
        my $well = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $index });
        unless ($well) {
            update_status($self, $c, $miseq, $index, 'Plated');
            $well = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $index });
        }
        my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $plate->{id}, name => $result })->as_hash;
        my $exp_record = $c->model('Golgi')->schema->resultset('MiseqProjectWellExp')->find({ miseq_well_id => $well->as_hash->{id}, miseq_exp_id => $miseq_exp->{id} });
        my $exp_params = {
            miseq_well_id           => $well->as_hash->{id},
            miseq_exp_id            => $miseq_exp->{id},
            classification          => $class,
        };

        if ($exp_record) {
            $exp_params->{id} = $exp_record->as_hash->{id};
            delete $exp_params->{miseq_well_id};
            if ($exp_record->as_hash->{classification} ne $class) {
                $c->model('Golgi')->update_miseq_well_experiment( $exp_params );
            }
        } else {
            $c->model('Golgi')->create_miseq_well_experiment( $exp_params );
        }
    }
    return;
}

sub find_classes {
    my ($c, $miseq, $index, $selection) = @_;

    my $result;
    my $plate = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash;
    my $well = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->find({ miseq_plate_id => $plate->{id}, illumina_index => $index });
    unless ($well) {
        return;
    }
    $well = $well->as_hash;

    try {
        my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $plate->{id}, name => $selection })->as_hash;
        my $well_exp = $c->model('Golgi')->schema->resultset('MiseqProjectWellExp')->find({ miseq_well_id => $well->{id}, miseq_exp_id => $miseq_exp->{id} })->as_hash;
        $result = $well_exp->{classification};
    } catch {
        $result = 'Not called';
    };

    return $result;
}

sub get_efficiencies {
    my ($c, $miseq) = @_;

    my $miseq_id = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->as_hash->{id};
    my $experiments = $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({ miseq_id => $miseq_id });

    my $efficiencies = {
        nhej => 0,
        total => 0,
    };

    while (my $exp_rs = $experiments->next) {
        my $exp = {
            nhej    => $exp_rs->mutation_reads,
            total   => $exp_rs->total_reads,
        };
        $efficiencies->{$exp_rs->name} = $exp;
        $efficiencies->{all}->{nhej} += $exp_rs->mutation_reads;
        $efficiencies->{all}->{total} += $exp_rs->total_reads;
        $efficiencies->{$exp_rs->gene}->{nhej} += $exp_rs->mutation_reads;
        $efficiencies->{$exp_rs->gene}->{total} += $exp_rs->total_reads;
    }

    return $efficiencies;
}

__PACKAGE__->meta->make_immutable;

1;
