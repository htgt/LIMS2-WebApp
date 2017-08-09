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
use Try::Tiny;
use POSIX qw/floor/;
use LIMS2::Model::Util::Miseq qw( convert_index_to_well_name wells_generator );

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

    my $plate_id = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq })->id;
    my $miseq_plate = $c->model('Golgi')->schema->resultset('MiseqPlate')->find({ plate_id => $plate_id })->as_hash;
    if ($miseq_plate->{'384'} == 1 ) {
        my $quadrants = experiment_384_distribution($c, $miseq, $plate_id, $miseq_plate->{id});
        $c->stash->{quadrants} = encode_json({ summary => $quadrants });
    }

    my $overview = get_experiments($c, $miseq, 'genes');
    my $ov_json = encode_json ({ summary => $overview });
    my $json = encode_json ({ summary => generate_summary_data($c, $miseq, $plate_id, $miseq_plate->{id}, $overview) });
    my $gene_keys = get_genes($c, $overview);
    my $revov = encode_json({ summary => $gene_keys });
    my @exps = sort keys %$overview;
    my @genes = sort keys %$gene_keys;
    my $efficiencies = encode_json ({ summary => get_efficiencies($c, $miseq_plate->{id}) });

    $c->stash(
        wells => $json,
        experiments => \@exps,
        miseq => $miseq,
        overview => $ov_json,
        genes => \@genes,
        gene_exp => $revov,
        efficiency => $efficiencies,
        large_plate => $miseq_plate->{'384'},
    );

    return;
}

sub point_mutation_allele : Path('/user/point_mutation_allele') : Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;
    my $index = $c->req->param('oligoIndex');
    my $exp_sel = $c->req->param('exp');
    my $miseq = $c->req->param('miseq');
    my $updated_status = $c->req->param('statusOption');

    my $well_name = convert_index_to_well_name($index);

    my $plate = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq })->as_hash;
    my $well_id = $c->model('Golgi')->schema->resultset('Well')->find({ plate_id => $plate->{id}, name => $well_name })->id;
    my $miseq_plate_id = $c->model('Golgi')->schema->resultset('MiseqPlate')->find({ plate_id => $plate->{id} })->id;
    my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $miseq_plate_id, name => $exp_sel })->as_hash;

    check_class($self, $c, $miseq_plate_id, $well_id, $plate->{id});

$DB::single=1;
    if ($updated_status) {
        update_status($self, $c, $miseq_exp->{id}, $well_id, $updated_status);
    }

    my $matching_criteria = $exp_sel || "[A-Za-z0-9_]+";
    my $regex = "S" . $index . "_exp" . $matching_criteria;
    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
    my @files = find_children($base, $regex); #Structure - S(Index)_exp(Experiment)

    #Get all well experiment details relating to well
    my @exps;
    foreach my $file (@files) {
        my @matches = ($file =~ /S\d+_exp([A-Za-z0-9_]+)/g); #Capture experiment name i.e. (GPR35_1)
        foreach my $match (@matches) {
            my $exp_rs = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $miseq_plate_id, name => $match })->as_hash;
            my $well_exp = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ well_id => $well_id, miseq_exp_id => $exp_rs->{id} })->as_hash;

            my $rs = {
                id      => $match,
                class   => $well_exp->{class},
                gene    => $exp_rs->{gene},
                status  => $well_exp->{status} || 'Plated',
            };
            push (@exps, $rs);
        }
    }
    @exps = sort { $a->{id} cmp $b->{id} } @exps;

    my @status = [ sort map { $_->id } $c->model('Golgi')->schema->resultset('MiseqStatus')->all ];
    my $states = encode_json({ summary => @status });
    
    my @classifications = map { $_->id } $c->model('Golgi')->schema->resultset('MiseqClassification')->all;

    $c->stash(
        miseq       => $miseq,
        oligo_index => $index,
        experiments => \@exps,
        well_name   => $well_name,
        indel       => '1b.Indel_size_distribution_percentage.png',
        status      => $states,
        classifications => \@classifications,
    );

    return;
}

sub browse_point_mutation : Path('/user/browse_point_mutation') : Args(0) {
    my ( $self, $c ) = @_;

    my @miseqs = sort { $b->{date} cmp $a->{date} } map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqPlate')->search({ }, { rows => 15 });
    $c->stash(
        miseqs => \@miseqs,
    );

    return;
}

sub create_miseq_plate : Path('/user/create_miseq_plate') : Args(0) {
    my ( $self, $c ) = @_;    
    #Only used for navigation purposes. All data retrieval and submission is dynamic thus handled by APIs
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


sub generate_summary_data {
    my ($c, $miseq, $plate_id, $miseq_id, $overview) = @_;

    my $wells;
    my @well_conversion = wells_generator();

    my $exp_ref;
    my @miseq_exp_rs = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({ miseq_id => $miseq_id });
    foreach my $miseq_exp (@miseq_exp_rs) {
        my @well_exps = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $miseq_exp->{id} });
        foreach my $well (@well_exps) {
            $exp_ref->{$well->{well_name}}->{$miseq_exp->{name}} = {
                class   => $well->{class} || 'Not called',
                status  => $well->{status} || 'Plated',
            };
        }
    }

    my $blank = {
        class   => 'Not called',
        status  => 'Plated',
    };
$DB::single=1;
    for (my $index = 1; $index < 385; $index++) { 
        #Could use wells but then we'd lose the ability to drag and drop files into miseq.
        #Staying till standalone miseq work begins
        my $well_name = $well_conversion[$index - 1];

        my $regex = "S" . $index . "_exp[A-Za-z0-9_]+";
        my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
        my @files = find_children($base, $regex);
        my @exps;
        foreach my $file (@files) {
            #Get all experiments on this well
            my @matches = ($file =~ /S$index\_exp([A-Za-z0-9_]+)/g);
            foreach my $match (@matches) {
                push (@exps, $match);
            }
        }

        @exps = sort @exps;
        my @selection;
        my $percentages;
        my @found_exps;
        my $details;
        foreach my $exp (@exps) {
            foreach my $gene ($overview->{$exp}) {
                push (@selection, $gene);
            }

            my $quant = find_file($base, $index, $exp);

            if ($quant) {
                my $fh;
                open ($fh, '<:encoding(UTF-8)', $quant) or die "$!";
                my @lines = read_file_lines($fh);
                close $fh;

                $percentages->{$exp}->{nhej} = ($lines[1] =~ qr/^,- Unmodified:(\d+)/)[0];
                $percentages->{$exp}->{wt} = ($lines[2] =~ qr/^,- NHEJ:(\d+)/)[0];
                $percentages->{$exp}->{hdr} = ($lines[3] =~ qr/^,- HDR:(\d+)/)[0];
                $percentages->{$exp}->{mix} = ($lines[4] =~ qr/^,- Mixed HDR-NHEJ:(\d+)/)[0];

                push(@found_exps, $exp); #In case of missing data
            }
            $details->{$exp} = $exp_ref->{$well_name}->{$exp} ? $exp_ref->{$well_name}->{$exp} : $blank;
        }
        #Genes, Barcodes and Status are randomly generated at the moment
        $wells->{sprintf("%02d", $index)} = {
            gene        => \@selection,
            experiments => \@found_exps,
            #barcode     => [$ug->create_str(), $ug->create_str()],
            percentages => $percentages,
            details     => $details,
        };
    }
$DB::single=1;
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
    my ($self, $c, $miseq_exp, $well_id, $status) = @_;

    my $well_details = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ well_id => $well_id, miseq_exp_id => $miseq_exp });
    my $params;
    if ($well_details) {
        $well_details = $well_details->as_hash;
        if ($well_details->{status} ne $status) {
            $params = {
                id      => $well_details->{id},
                status  => $status,
            };
            $c->model('Golgi')->update_miseq_plate_well($params);
        }
    }
    else {
        $params = {
            well_id         => $well_id,
            miseq_exp_id    => $miseq_exp,
            status          => $status,
        };
        $c->model('Golgi')->create_miseq_well_experiment($params);
    }
    return;
}


sub check_class {
    my ($self, $c, $miseq, $well_id, $plate_id) = @_;

    my $params = $c->req->params;
    my $result;

    #Page contains a class changer for each exp attached to the well. If one is changed, it'll appear in the request e.g. classPTK2B
    foreach my $key (keys %$params) {
        my @matches = ($key =~ /^class([A-Za-z0-9_]+)$/g);
        if (@matches) {
            $result = $matches[0];
        }
    }

    if ($result) {
        my $class = $c->req->param('class' . $result);
        
        my $exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $miseq, name => $result })->as_hash;
        my $well_exp = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ well_id => $well_id, miseq_exp_id => $exp->{id} });
        my $exp_params = {
            well_id                 => $well_id,
            miseq_exp_id            => $exp->{id},
            classification          => $class,
        };

        if ($well_exp) {
            $exp_params->{id} = $well_exp->as_hash->{id};
            delete $exp_params->{well_id};
            if ($well_exp->as_hash->{classification} ne $class) {
                $c->model('Golgi')->update_miseq_well_experiment($exp_params);
            }
        } else {
            $c->model('Golgi')->create_miseq_well_experiment($exp_params);
        }
    }
    return;
}

sub get_efficiencies {
    my ($c, $miseq_id) = @_;

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
