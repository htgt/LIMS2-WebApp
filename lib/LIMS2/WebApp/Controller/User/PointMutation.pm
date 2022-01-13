package LIMS2::WebApp::Controller::User::PointMutation;

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use Data::UUID;
use File::Find;
use Text::CSV;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use POSIX qw/floor/;
use LIMS2::Model::Util::Miseq qw(
    convert_index_to_well_name
    generate_summary_data
    find_folder
    find_file
    find_child_dir
    wells_generator
    miseq_genotyping_info
);
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data );
use List::Util qw(min max);

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
    my $selection = $c->req->param('experiment');
    my $plate_id = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq })->id;
    my $miseq_plate = $c->model('Golgi')->schema->resultset('MiseqPlate')->find({ plate_id => $plate_id })->as_hash;
    my $summary_data = generate_summary_data($c, $plate_id, $miseq_plate->{id});


    if ($miseq_plate->{'384'} == 1 ) {
        my $quadrants = experiment_384_distribution($c, $summary_data->{ranges});
        $c->stash->{quadrants} = encode_json({ summary => $quadrants });
    }

    my $overview = $summary_data->{overview};
    my $ov_json = encode_json ({ summary => $overview });

    my $json = encode_json ({ summary => $summary_data->{wells}});

    my ($gene_keys, $gene_prefix_keys) = get_genes($c, $overview);


    my $revov = encode_json({ summary => $gene_keys });
    my $prefix = encode_json({summary => $gene_prefix_keys});
    my @exps = sort keys %$overview;
    my @genes = sort keys %$gene_keys;
    my @gene_prefixs = sort keys %$gene_prefix_keys;
    my $efficiencies = encode_json ({ summary => get_efficiencies($c, $miseq_plate->{id}) });

    my $crispr;
    my $gene_crisprs;
    my $revgc;
    my @gene_names;
    my @uniq_crisprs;

    foreach my $design (@genes){
        my $crispr_gene;
        ($crispr_gene,$crispr) = split /\s*_\s*/, $design;
        if ( ! defined $crispr || $crispr =~ /[a-zA-Z]/ || $crispr eq ''){$crispr = '1'};

        my $design_exps = $gene_keys->{$design};

        foreach my $design_exp (@{$design_exps}){
            push (@{$gene_crisprs->{$crispr}->{$crispr_gene}},$design_exp);
        }

        push (@gene_names, $crispr_gene);
        push (@uniq_crisprs, $crispr);

    }
    @gene_names = uniq @gene_names;
    @uniq_crisprs = uniq @uniq_crisprs;

    my @crisprs = sort values %$gene_crisprs;

    foreach my $design (@genes){
        my $revcg;

        ($revcg,$crispr) = split /\s*_\s*/, $design;
        if ( ! defined $crispr || $crispr =~ /[a-zA-Z]/ || $crispr eq ''){$crispr = '1'};

        my @rev_design_exps = $gene_keys->{$design};

        foreach my $rev_design_exp (@rev_design_exps){
            push (@{$revgc->{$crispr}->{$revcg}},$rev_design_exp);
        }
        push (@{$revgc->{$revcg}},$crispr);
    }

    my $designs = encode_json({summary => $gene_crisprs});
    my $designs_reverse = encode_json({summary => $revgc});

    $c->stash(
        wells => $json,
        experiments => \@exps,
        miseq => $miseq,
        overview => $ov_json,
        genes => \@gene_names,
        gene_exp => $revov,
        efficiency => $efficiencies,
        large_plate => $miseq_plate->{'384'},
        selection => $selection || 'All',
        designs => $designs,
        designs_reverse => $designs_reverse,
        gene_crispr => $prefix,
        uniq_crisprs => \@uniq_crisprs,

    );

    return;
}

sub point_mutation_allele : Path('/user/point_mutation_allele') : Args(0) {
    my ( $self, $c ) = @_;

    my $index = $c->req->param('oligoIndex');

    my $exp_sel = $c->req->param('exp');
    my $miseq = $c->req->param('miseq');
    my $updated_status = $c->req->param('statusOption');

    my $well_name = convert_index_to_well_name($index);

    my $plate = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq })->as_hash;
    my $miseq_plate = $c->model('Golgi')->schema->resultset('MiseqPlate')->find({ plate_id => $plate->{id} })->as_hash;
    my $miseq_plate_id = $miseq_plate->{id};

    my $matching_criteria = $exp_sel || "[A-Za-z0-9_]+";
    my $regex = "S" . $index . "_exp" . $matching_criteria;

    my @exps = ();
    my $well_id;
    try {
        $well_id = $c->model('Golgi')->schema->resultset('Well')->find({ plate_id => $plate->{id}, name => $well_name })->id;
        update_tracking($self, $c, $miseq_plate_id, $plate->{id}, $well_id);
        @exps = get_well_exps($c, $miseq, $regex, $miseq_plate_id, $well_id);
    } catch {
        $c->log->debug("No well found.");
    };

    my @status = map { $_->id } $c->model('Golgi')->schema->resultset('MiseqStatus')->all;
    my @classifications = map { $_->id } $c->model('Golgi')->schema->resultset('MiseqClassification')->search(undef, { order_by => { -asc => 'ordering' } });

    if ($exp_sel) {
        $c->stash->{selection} = $exp_sel;
    }

    my $well_limit = {
        0 => 96,
        1 => 384,
    };
    my $exp_hash;
    my $indels;
    my $counter = 0;

    while ( $exps[0][$counter] ) {
        my $exp = $exps[0][$counter]->{id};
        my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ name => $exp, miseq_id => $miseq_plate_id })->as_hash;
        my $miseq_well_exp = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ miseq_exp_id => $miseq_exp->{id}, well_id => $well_id })->as_hash;

        my @indel = map { $_->as_hash } $c->model('Golgi')->schema->resultset('IndelHistogram')->search({'miseq_well_experiment_id' => $miseq_well_exp->{id}});
        my $sum = 0;
        while (@indel) {
            my $row = shift @indel;
            $indels->{$exp}->{$row->{indel_size}} = $row->{frequency};
            $sum += $row->{frequency};
        }
        if ($miseq_well_exp->{total_reads}) {
            $indels->{$exp}->{'0'} = $miseq_well_exp->{total_reads} - $sum;
            my $min = min keys %{$indels->{$exp}};
            my $max = max keys %{$indels->{$exp}};
            for (my $i=$min -1; $i <= $max + 1; $i++) {
                unless (exists $indels->{$exp}->{$i}) {
                    $indels->{$exp}->{$i}=0;
                }
                my $indel_freq = {
                    indel       =>  $i,
                    frequency   =>  $indels->{$exp}->{$i}
                };

                push @{$exp_hash->{$exp}}, $indel_freq;
            }
        }
        $counter++;
    }
    if ($exp_hash) {
        $c->stash(indel_stats => encode_json($exp_hash));
    }
    $c->stash(
        miseq           => $miseq,
        oligo_index     => $index,
        experiments     => @exps,
        well_name       => $well_name,
        status          => \@status,
        classifications => \@classifications,
        max_wells       => $well_limit->{$miseq_plate->{384}},
    );
    return;
}


sub browse_point_mutation : Path('/user/browse_point_mutation') : Args(0) {
    my ( $self, $c ) = @_;

    my @miseqs = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqPlate')->search(
        { },
        {
            order_by => {-desc => 'id'}
        }
    );

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
    my ( $c, $range_summary ) = @_;
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
    my @col = $csv->column_names($csv->getline($fh));
    if ($col[5] =~  m/^min/gmi){
        my @heads = qw(experiment gene crispr strand amplicon min_index max_index nhej total hdr);
        $csv->column_names(\@heads);
    }
    else {
        my @heads = qw(experiment gene crispr strand amplicon range nhej total hdr);
        $csv->column_names(\@heads);
    }

    while (my $row = $csv->getline_hr($fh)) {
        next if $. < 2;
        if ($opt eq 'Range') {
            my $range;
            if ($row->{min_index} && $row->{max_index}){
                $range = $row->{min_index}."-".$row->{max_index};
            }
            else {
               $range = $row->{range};
            }
            $overview->{$row->{experiment}} = $range;
        } else {
            my @genes;
            push @genes, $row->{gene};
            $overview->{$row->{experiment}} = \@genes;
        }
    }
    return $overview;
}

sub get_genes {
    my ( $c, $ow) = @_;

    my $genes;
    my $gene_prefixs;
    foreach my $key (keys %$ow) {
        my @exps;
        foreach my $value (@{$ow->{$key}}) {
            my @gene = ($value =~ qr/^([A-Za-z0-9\-\_]*)/);
            push (@{$genes->{$gene[0]}}, $key);

            my @gene_prefix = ($value =~ qr/^([A-Za-z0-9-]*)/);
            push (@{$gene_prefixs->{$gene_prefix[0]}}, $key);
        }
    }
    return $genes, $gene_prefixs;
}

sub update_tracking {
    my ($self, $c, $miseq, $plate_id, $well_id) = @_;
    my $params = $c->req->params;
    my $result;
    #Page contains a class changer for each exp attached to the well. If one is changed, it'll appear in the request e.g. classPTK2B
    foreach my $key (keys %$params) {
        my @matches = ($key =~ /^(?:(class|status))([A-Za-z0-9_]+)$/g);
        if (@matches) {
            $result = $matches[1];
        }
    }

    if ($result) {
        my $class = $c->req->param('class' . $result);
        my $status = $c->req->param('status' . $result);

        my $exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $miseq, name => $result })->as_hash;
        my $well_exp = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ well_id => $well_id, miseq_exp_id => $exp->{id} });
        my $exp_params = {
            well_id         => $well_id,
            miseq_exp_id    => $exp->{id},
        };
        my $check;
        if ($class) {
            $check = 'classification';
            $exp_params->{$check} = $class;
        }
        if ($status) {
            $check = 'status';
            $exp_params->{$check} = $status;
        }
        if ($well_exp) {
            $exp_params->{id} = $well_exp->as_hash->{id};
            delete $exp_params->{well_id};
            unless ($exp_params->{$check} eq $well_exp->as_hash->{$check}) {
                $c->model('Golgi')->update_miseq_well_experiment($exp_params);
            }
        } else {
            $exp_params->{classification} = $exp_params->{classification} ? $exp_params->{classification} : 'Not Called';
            $exp_params->{status} = $exp_params->{status} ? $exp_params->{status} : 'Plated';
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
            nhej    => $exp_rs->nhej_reads,
            total   => $exp_rs->total_reads,
        };
        $efficiencies->{$exp_rs->name} = $exp;
        $efficiencies->{all}->{nhej} += $exp_rs->nhej_reads;
        $efficiencies->{all}->{total} += $exp_rs->total_reads;
        $efficiencies->{$exp_rs->gene}->{nhej} += $exp_rs->nhej_reads;
        $efficiencies->{$exp_rs->gene}->{total} += $exp_rs->total_reads;
    }

    return $efficiencies;
}



sub get_well_exps {
    my ($c, $miseq, $regex, $miseq_id, $well_id) = @_;
    my @exps;
    my $miseq_well_exp_rs =  $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ well_id => $well_id });
    my $next_miseq_well_exp;
    while ($next_miseq_well_exp = $miseq_well_exp_rs->next){
        $next_miseq_well_exp = $next_miseq_well_exp->as_hash;
        my $miseq_exp =  $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ id => $next_miseq_well_exp->{miseq_exp_id} })->as_hash;
        my $ref = { 'status'    => $next_miseq_well_exp->{status},
                    'gene'      => $miseq_exp->{gene},
                    'class'     => $next_miseq_well_exp->{classification},
                    'id'        => $miseq_exp->{name},
                };
        push (@exps, $ref);
    }
    @exps = sort { $a->{id} cmp $b->{id} } @exps;
    return \@exps;
}

#THE BELLOW SUB WAS REPLACED BY get_well_exps WHEN THE DATA WAS MIGRATED FROM THE FILE SYSTEM TO THE DATABASE.
sub get_well_exp_graphs_old {
    my ($c, $miseq, $regex, $miseq_id, $well_id) = @_;

    my @exps;
    my @files = find_child_dir($miseq, $regex); #Structure - S(Index)_exp(Experiment)
    foreach my $file (@files) {
        my @matches = ($file =~ /S\d+_exp([A-Za-z0-9_]+)/g); #Capture experiment name i.e. (GPR35_1)
        foreach my $match (@matches) {
            my $exp_rs;
            my $well_exp;
            my $rs = {
                id      => $match,
                gene    => $exp_rs->{gene},
            };
            try {
                $exp_rs = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ miseq_id => $miseq_id, name => $match })->as_hash;
                $well_exp = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ well_id => $well_id, miseq_exp_id => $exp_rs->{id} })->as_hash;
                $rs->{status} = $well_exp->{status} ? $well_exp->{status} : 'Plated';
                $rs->{class} = $well_exp->{classification} ? $well_exp->{classification} : 'Not Called';
            } catch {
                $c->log->debug("Miseq experiment / well not found. Exp: " . $match . " Well: " . $well_id);
                $rs->{status} = 'Plated';
                $rs->{class} = 'Not Called';
            };

            push (@exps, $rs);
        }
    }
    @exps = sort { $a->{id} cmp $b->{id} } @exps;

    return \@exps;
}


__PACKAGE__->meta->make_immutable;

1;
