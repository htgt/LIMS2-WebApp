package LIMS2::Model::Util::Miseq;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              miseq_well_processes
              wells_generator
              convert_index_to_well_name
              generate_summary_data
              find_folder
              find_file
              find_child_dir
              read_file_lines
              find_miseq_data_from_experiment
              query_miseq_details
              damage_classifications
              miseq_genotyping_info
              read_alleles_frequency_file
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use JSON;
use File::Find;
use Const::Fast;
use List::Util qw( sum );
use List::MoreUtils qw( uniq );
use SQL::Abstract;
use Bio::Perl;

const my $QUERY_INHERITED_EXPERIMENT => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, crispr_id, design_id, start_well_id) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id, pc.crispr_id, pd.design_id, pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     LEFT JOIN process_crispr pc ON pr_out.process_id = pc.process_id
     LEFT JOIN process_design pd ON pr_out.process_id = pd.process_id
     WHERE pr_out.well_id IN (select id from wells where plate_id = ?)
     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id, pc.crispr_id, pd.design_id, well_hierarchy.start_well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
     LEFT JOIN process_crispr pc ON pr_out.process_id = pc.process_id
     LEFT JOIN process_design pd ON pr_out.process_id = pd.process_id
)
SELECT DISTINCT exp.id AS experiment_id, wh.crispr_id, wh.design_id, output_well_id, op.type_id, start_well_id, sw.name AS start_well_name
FROM well_hierarchy wh
LEFT JOIN experiments exp ON exp.crispr_id = wh.crispr_id AND exp.design_id = wh.design_id
INNER JOIN wells ow ON ow.id=output_well_id
INNER JOIN plates op ON ow.plate_id=op.id
INNER JOIN wells sw ON sw.id=start_well_id
WHERE op.type_id IN ('EP_PIPELINE_II','PIQ','FP')
EOT

#The two queries are meant for finding Miseq calls from a sibling or distant-relation plate. 
#The second pr_out.well_id preserves the well id we started with. Using that we can trace exactly which well has lineage to the miseq classifications
#Crisprs and Designs are attached to processes at the highest Pipeline II level (EPII).
#Miseq Parents can only consist of FP and PIQ plates so we must preserve the parent branch to the EPII plate

const my $QUERY_MISEQ_SIBLINGS => <<'EOT';
WITH RECURSIVE descendants(process_id, input_well_id, output_well_id, start_well_id) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    %s
    UNION
    SELECT pr.id, pr_in.well_id, pr_out.well_id, start_well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN descendants ON descendants.output_well_id = pr_in.well_id
)
SELECT DISTINCT dest.input_well_id, dest.start_well_id, dest.process_id, well_in.name, plate_in.name,
well_out.id, well_out.name, plate_out.name, mp.id, me.experiment_id AS exp, me.name, mwe.id AS mwe_id, mwe.classification, mwe.frameshifted
FROM descendants dest
INNER JOIN wells well_in ON input_well_id=well_in.id
INNER JOIN plates plate_in ON well_in.plate_id=plate_in.id
INNER JOIN wells well_out ON output_well_id=well_out.id
INNER JOIN plates plate_out ON well_out.plate_id=plate_out.id
INNER JOIN miseq_plate mp ON plate_out.id=mp.plate_id
INNER JOIN miseq_experiment me ON mp.id=me.miseq_id
INNER JOIN miseq_well_experiment mwe ON mwe.well_id=well_out.id AND me.id=mwe.miseq_exp_id
%s
ORDER BY dest.start_well_id ASC
EOT

#Following on from the ancestory query, we place the potential parent wells (FP, PIQ) into this query to search for Miseq offspring 
#Find classifications which share a common ancestor (Usually FP) with our supplied plate (i.e. PIQ)


sub query_miseq_details {
    my ($self, $plate_id) = @_;

    my @ancestor_rows = @{ _find_inherited_experiment($self, $plate_id) };
    my @ancestor_headers = qw(
        exp_id
        crispr_id
        design_id
        well_id
        type_id
        start_well_id
        start_well_name
    );
    my @ancestor_results = _prepare_headers({ headers => \@ancestor_headers, results => \@ancestor_rows });
    my @epii = uniq map { $_->{exp_id} } grep { $_->{type_id} eq 'EP_PIPELINE_II'} @ancestor_results;
    my @parents = uniq map { $_->{well_id} } grep { $_->{type_id} ne 'EP_PIPELINE_II'} @ancestor_results;

    my $parent_mapping;
    map { push( @{ $parent_mapping->{ $_->{well_id} } },  $_->{start_well_name} ) } @ancestor_results;

    my @offspring_headers = qw(
        ancestor_well_id
        origin_well_id
        origin_process_id
        origin_well_name
        origin_plate_name
        miseq_well_id
        miseq_well_name
        miseq_plate_name
        miseq_plate_details_id
        experiment_id
        miseq_experiment_name
        miseq_well_exp_id
        miseq_well_exp_classification
        miseq_well_exp_frameshift
    );
    my @offspring_rows = @{ _traverse_process_tree($self, { parents => \@parents, experiments => \@epii }) };
    my @miseq_results = _prepare_headers({ headers => \@offspring_headers, results => \@offspring_rows });

    map { $_->{sibling_origin_wells} = $parent_mapping->{ $_->{origin_well_id} } } @miseq_results;

    return @miseq_results;
}

sub _prepare_headers {
    my ($data) = @_;

    my @headers = @{ $data->{headers} };
    my @formatted_rows;
    foreach my $miseq_row (@{ $data->{results} }) {
        my %mapping;
        @mapping{@headers} = @{ $miseq_row };
        push @formatted_rows, \%mapping;
    }

    return @formatted_rows;
}

sub _find_inherited_experiment {
    my ($self, $plate_id) = @_;

    my $query = $QUERY_INHERITED_EXPERIMENT;
    return $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute( $plate_id );
            $sth->fetchall_arrayref;
        }
    );
}

sub _traverse_process_tree {
    my ($self, $data_arrays) = @_;

    my $query = $QUERY_MISEQ_SIBLINGS;

    my $parent_well_ids = $data_arrays->{parents};
    my $experiments = $data_arrays->{experiments};

    my $sql = SQL::Abstract->new;
    my ($well_where, @well_binds) = $sql->where(
        { 'pr_out.well_id' => { -in => $parent_well_ids } },
    );
    my ($exps_where, @exps_binds) = $sql->where(
        { experiment_id => { -in => $experiments } },
    );

    $query = sprintf ($query, $well_where, $exps_where);

    return $self->schema->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->prepare_cached($query);
            $sth->execute(@{ $parent_well_ids }, @{ $experiments });
            $sth->fetchall_arrayref;
        }
    );
}

sub damage_classifications {
    my (@query_results) = @_;

    my $class_mapping;
    foreach my $result (@query_results) {
        if ($result->{miseq_classification} ne 'Not Called' && $result->{miseq_classification} ne 'Mixed') {
            my $class_details = {
                classification  => $result->{miseq_classification},
                experiment_id   => $result->{experiment_id},
                miseq_exp_name  => $result->{miseq_experiment_name},
                miseq_plate_name => $result->{miseq_plate_name},
            };
            foreach my $sib_well (@{ $result->{sibling_origin_wells} }) {
                push (@{ $class_mapping->{$sib_well} }, $class_details);
            }
        }
    }

    return $class_mapping;
}

const my $QUERY_MISEQ_DATA_BY_EXPERIMENT_ID => <<'EOT';
SELECT me.name, mwe.classification, mwell.name, mplate.name, fpwell.name, fp.name
FROM miseq_experiment me
LEFT JOIN miseq_well_experiment mwe ON mwe.miseq_exp_id=me.id
LEFT JOIN wells mwell ON mwe.well_id=mwell.id
LEFT JOIN plates mplate ON mwell.plate_id=mplate.id
INNER JOIN process_output_well pow ON mwell.id=pow.well_id
LEFT JOIN process_input_well piw ON pow.process_id=piw.process_id
LEFT JOIN wells fpwell ON piw.well_id=fpwell.id
INNER JOIN plates fp ON fpwell.plate_id=fp.id AND me.parent_plate_id=fp.id
WHERE experiment_id = ? AND mwe.classification != 'Not Called' AND mwe.classification != 'Mixed';
EOT

sub find_miseq_data_from_experiment {
    my ($c, $experiment_id) = @_;

    my @results = @{ _find_miseq_data_by_exp($c->model('Golgi'), $experiment_id) };

    my @headers = qw(
        miseq_experiment_name
        classification
        miseq_well_name
        miseq_plate_name
        parent_well_name
        parent_plate_name
    );
    my @miseq_relations;
    foreach my $miseq_well_relation (@results) {
        my %mapping;
        @mapping{@headers} = @{ $miseq_well_relation };
        push @miseq_relations, \%mapping;
    }

    return @miseq_relations;
}

sub _find_miseq_data_by_exp {
    my ($self, $experiment_id) = @_;

    my $query = $QUERY_MISEQ_DATA_BY_EXPERIMENT_ID;
    return $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute( $experiment_id );
            $sth->fetchall_arrayref;
        }
    );
}

=head
sub find_miseq_data_from_experiment {
    my ($c, $experiment_id) = @_;
    my $rs = $c->model('Golgi')->schema->resultset('MiseqExperiment')->search(
    {

        experiment_id   => $experiment_id,
        'miseq_well_experiments.classification'  => { '!=' => 'Not Called' },
        'miseq_well_experiments.classification'  => { '!=' => 'Mixed' },
        'plate_2.id' => { -ident => 'parent_plate_id' },
    },
    {
        join => {
            'miseq_well_experiments' => [{
                'well' => [
                    'plate',
                    {
                        'process_output_wells' => {
                            'process' => {
                                'process_input_wells' => {
                                    'well' => 'plate',
                                }
                            }
                        }
                    }
                ],
            }],
        },
        prefetch => 'parent_plate',
    });
    

    my @miseq_experiments;
    while (my $miseq_exp = $rs->next) {
        my $result = {
            parent_plate    => $miseq_exp->parent_plate->as_hash,
            #clones          => map { clone_information($_) } @{ $miseq_exp->miseq_well_experiments },
        };
        while (my $me = $miseq_exp->miseq_well_experiments->next) {
            clone_information($me);
        }
        print Dumper $miseq_exp->parent_plate->name;
        push (@miseq_experiments, $result);
    }

    return \@miseq_experiments;
}

sub clone_information {
    my ($well_exp) = @_;
    my $pows = $well_exp->well->process_output_wells;

    while (my $pow = $pows->next) {
        my $piws = $pow->process->process_input_wells;
        while (my $piw = $piws->next) {
            my $dets = $well_exp->as_hash;
            $dets->{clone} = $piw->well->plate->name . '_' . $piw->well->name;
            print Dumper $dets;
        }
    }

    return;
}
=cut

sub miseq_well_processes {
    my ($c, $params) = @_;
    my $well_data = $params->{data};

    my $miseq_well_hash;
    foreach my $fp (keys %{$well_data}) {
        my $process = $well_data->{$fp}->{process};
        foreach my $miseq_well_name (keys %{$well_data->{$fp}->{wells}}) {
            my $fp_well = $well_data->{$fp}->{wells}->{$miseq_well_name};
            $miseq_well_hash->{$process}->{$miseq_well_name}->{$fp} = $fp_well;
        }
    }

    my $process_types = {
        nhej    => 'miseq_no_template',
        oligo   => 'miseq_oligo',
        vector  => 'miseq_vector',
    };

    foreach my $process (keys %{$miseq_well_hash}) {
        miseq_well_relations($c, $miseq_well_hash->{$process}, $params->{name}, $params->{user}, $params->{time}, $process_types->{$process});
    }

    return;
}

sub miseq_well_relations {
    my ($c, $wells, $miseq_name, $user, $time, $process_type) = @_;

    foreach my $well (keys %{$wells}) {
        my @parent_wells;
        foreach my $fp (keys %{$wells->{$well}}) {
            my $parent_well = {
                plate_name  => $fp,
                well_name   => $wells->{$well}->{$fp},
            };
            push (@parent_wells, $parent_well);
        }
        my $process = {
            input_wells => \@parent_wells,
            output_wells => [{
                plate_name  => $miseq_name,
                well_name   => $well,
            }],
            type => $process_type,
        };

        my $params = {
            plate_name      => $miseq_name,
            well_name       => $well,
            process_data    => $process,
            created_by      => $user,
            created_at      => $time,
        };
        my $lims_well = $c->create_well($params);
    }

    return;
}

sub convert_index_to_well_name {
    my $index = shift;

    my @wells = wells_generator();
    my $name = $wells[$index - 1];

    return $name;
}

sub wells_generator {
    my $name_to_index = shift;
    my @well_names;
    my $quads = {
        '0' => {
            mod     => 0,
            letters => ['A','B','C','D','E','F','G','H'],
        },
        '1' => {
            mod     => 12,
            letters => ['A','B','C','D','E','F','G','H'],
        },
        '2' => {
            mod     => 0,
            letters => ['I','J','K','L','M','N','O','P'],
        },
        '3' => {
            mod     => 12,
            letters => ['I','J','K','L','M','N','O','P'],
        }
    };

    for (my $ind = 0; $ind < 4; $ind++) {
        @well_names = well_builder($quads->{$ind}, @well_names);
    }

    if ($name_to_index) {
        my %well_indexes;
        @well_indexes{@well_names} = (1..$#well_names+1);
        return \%well_indexes;
    }

    return @well_names;
}

sub well_builder {
    my ($mod, @well_names) = @_;

    foreach my $number (1..12) {
        my $well_num = $number + $mod->{mod};
        foreach my $letter ( @{$mod->{letters}} ) {
            my $well = sprintf("%s%02d", $letter, $well_num);
            push (@well_names, $well);
        }
    }

    return @well_names;
}

sub generate_summary_data {
    my ($c, $miseq, $plate_id, $miseq_id, $overview) = @_;

    my $wells;
    my @well_conversion = wells_generator();

    my $blank = {
        class           => 'Not Called',
        status          => 'Plated',
        frameshifted    => 0,
    };
    my $exp_ref;
    my @miseq_exp_rs = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({ miseq_id => $miseq_id });
    foreach my $miseq_exp (@miseq_exp_rs) {
        my @well_exps = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $miseq_exp->{id} });
        foreach my $well (@well_exps) {
            $exp_ref->{$well->{well_name}}->{$miseq_exp->{name}} = {
                class       => $well->{classification} ? $well->{classification} : $blank->{class},
                status      => $well->{status} ? $well->{status} : $blank->{status},
                frameshift  => $well->{frameshifted} ? $well->{frameshifted} : $blank->{frameshifted},
            };
        }
    }

    for (my $index = 1; $index < 385; $index++) {
        #Could use wells but then we'd lose the ability to drag and drop files into miseq.
        #Staying till standalone miseq work begins
        my $well_name = $well_conversion[$index - 1];

        my $regex = "S" . $index . "_exp[A-Za-z0-9_]+";
        my @files = find_child_dir($miseq, $regex);
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

            my $quant_data = read_quant_file($miseq, $index, $exp);
            if ($quant_data) {
                $percentages->{$exp} = $quant_data;
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
    return $wells;
}

sub read_alleles_frequency_file {
    my ($c, $miseq, $index, $exp, $threshold, $percentage_bool) = @_;
$DB::single=1;
    my $path = find_file($miseq, $index, $exp, 'Alleles_frequency_table.txt');
    if (!defined $path) {
        return { error => 'No path available' };
    }

    my $fh;
    open ($fh, '<:encoding(UTF-8)', $path) or die "$!";
    my @lines = read_file_lines($fh);
    close $fh;

    my $res;
    if ($percentage_bool) {
        @lines = _find_read_quantification_gt_threshold($threshold, @lines);
    } elsif ($threshold != 0) {
        @lines = @lines[0..$threshold];
    } 

    return @lines;
}

sub _find_read_quantification_gt_threshold {
    my ($threshold, @lines) = @_;
$DB::single=1;
    my @relevant_reads;
    my $count = 1;
    my $read_perc = 100;
    
    push @relevant_reads, $lines[0];
    while ($read_perc > $threshold) {
        push @relevant_reads, $lines[$count];
        $count++;
        my @cells = split /,/, $lines[$count];
        $read_perc = $cells[-1];
    }

    return @relevant_reads;
}

sub read_quant_file {
    my ($miseq, $index, $exp) = @_;

    my $quant = find_file($miseq, $index, $exp, "Quantification_of_editing_frequency.txt");

    if ($quant) {
        my $fh;
        open ($fh, '<:encoding(UTF-8)', $quant) or die "$!";
        my @lines = read_file_lines($fh);
        close $fh;

        my $data = {
            wt      => ($lines[1] =~ qr/^,- Unmodified:(\d+)/)[0],
            nhej    => ($lines[2] =~ qr/^,- NHEJ:(\d+)/)[0],
            hdr     => ($lines[3] =~ qr/^,- HDR:(\d+)/)[0],
            mix     => ($lines[4] =~ qr/^,- Mixed HDR-NHEJ:(\d+)/)[0],
        };

        return $data;
    }

    return;
}

sub find_file {
    my ($miseq, $index, $exp, $file) = @_;
    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/S' . $index . '_exp' . $exp;

    my $charts = [];
    my $wanted = sub { _wanted($charts, $file) };

    find($wanted, $base);

    return @$charts[0];
}

sub find_folder {
    my ($path, $fh) = @_;

    my $res;
    while ( my $entry = readdir $fh ) {
        next unless $path . '/' . $entry;
        next if $entry eq '.' or $entry eq '..';
        my @matches = ($entry =~ /CRISPResso_on\S*_(S\S*$)/g); #Max 1

        $res = $matches[0];
    }

    return $res;
}

sub find_child_dir {
    my ($miseq, $reg) = @_;
    my $fh;

    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/';
    opendir ($fh, $base);
    my @files = grep {/$reg/} readdir $fh;
    closedir $fh;
    return @files;
}

sub read_file_lines {
    my ($fh, $plain) = @_;

    my @data;
    while (my $row = <$fh>) {
        chomp $row;
        if ($plain) {
            push(@data, $row);
        } else {
            push(@data, join(',', split(/\t/,$row)));
        }
    }

    return @data;
}

sub _wanted {
    return if ! -e;
    my ($charts, $file_name) = @_;

    push( @$charts, $File::Find::name ) if $File::Find::name =~ /$file_name/;

    return;
}

sub miseq_genotyping_info {
    my ($c, $well) = @_;
    my @related_qc = query_miseq_details($c->model('Golgi'), $well->plate_id);


    my $experiments = {
        well_id             => $well->id,
        barcode             => $well->barcode,
        well_name           => $well->name,
        plate_name          => $well->plate_name,
        cell_line           => $well->first_cell_line->name,
    };

    my $index_converter = wells_generator(1);
    my @overview_symbols;
    my @overview_gene_ids;
    my @overview_design_ids;
    foreach my $qc (@related_qc) {
        my $exp_rs = $c->model('Golgi')->schema->resultset('Experiment')->find({ id => $qc->{experiment_id} });
        my $design_rs = $exp_rs->design;
        my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };
        my @gene_symbols = $design_rs->gene_symbols($gene_finder);
        my @gene_ids = $design_rs->gene_ids;
        my $illumina_index = $index_converter->{ $qc->{miseq_well_name} };

        my $miseq_quant = read_quant_file( 
            $qc->{miseq_plate_name},
            $illumina_index,
            $qc->{miseq_experiment_name}
        );
        $miseq_quant = _calc_read_percentages($miseq_quant);
        my $qc_origin_well = $c->model('Golgi')->schema->resultset('Well')->find({ id => $qc->{miseq_well_id} });

        my @alleles_frequency = read_alleles_frequency_file($c, $qc_origin_well->plate_name, $illumina_index, $qc->{miseq_experiment_name}, 1, 1);

$DB::single=1;
        my @crisprs = map { $_->seq } $exp_rs->crispr;
        my @crispr_locs = crispr_location_in_amplicon($c, $alleles_frequency[1], @crisprs);

        my $alleles_table_data = {
            data    => _map_comma_string(@alleles_frequency),
            crisprs => @crispr_locs,
        };
        $experiments->{species} = $design_rs->species_id;
        my $exp_details = {
            experiment_id       => $exp_rs->id,
            read_counts         => $miseq_quant,
            gene                => _handle_singular(@gene_symbols),
            gene_id             => _handle_singular(@gene_ids),
            design_id           => $design_rs->id,
            crisprs             => join (',', @crisprs),
            qc_origin_plate     => $qc_origin_well->plate_name,
            qc_origin_well      => $qc_origin_well->name,
            species             => $design_rs->species_id,
            oligos              => $exp_rs->design->oligos_sorted,
            experiment_name     => $qc->{miseq_experiment_name},
            classification      => $qc->{miseq_well_exp_classification},
            frameshift          => $qc->{miseq_well_exp_frameshift},
            alleles_freq        => $alleles_table_data,
        };
use Data::Dumper;
print Dumper $exp_details;
        push (@{$experiments->{experiments}}, $exp_details);
        push (@overview_symbols, @gene_symbols);
        push (@overview_gene_ids, @gene_ids);
        push (@overview_design_ids, $design_rs->id);
    }

    $experiments->{gene} = _handle_singular(uniq @overview_symbols); 
    $experiments->{gene_id} = _handle_singular(uniq @overview_gene_ids);
    $experiments->{design_id} = _handle_singular(uniq @overview_design_ids);

    return $experiments;
}

sub _handle_singular {
    my @array = shift;

    return @array == 1 ? $array[0] : [ @array ];
}

sub _calc_read_percentages {
    my $calls = shift;

    my $total = 0;
    $total = sum values %$calls;
    my $factor = 100 / $total;
    
    my $perc;
    foreach my $class (keys %$calls) {
        my $call_perc = sprintf("%0.2f", $factor * $calls->{$class});
        $perc->{$class} = {
            count   => $calls->{$class},
            perc    => $call_perc,
        };
    }

    return $perc;
}

sub crispr_location_in_amplicon {
    my ($c, $amplicon, @crisprs) = @_;

    my @crispr_positions;
    foreach my $crispr (@crisprs) {
        my $loc = index($amplicon, $crispr);
        if ($loc == -1) {
            try {
                $loc = index($loc, revcom($crispr)->seq);
            } catch {
                $c->log->debug('Miseq allele frequency summary API: Can not find crispr in forward or reverse compliment');
            };
        }
        my $crispr_data = {
            crispr      => $crispr,
            position    => $loc,
        };
        push @crispr_positions, $crispr_data;
    }

    return @crispr_positions;
}

sub _map_comma_string {
    my (@reads) = @_;
$DB::single=1;
    my @headers = split /,/, shift @reads;
    my $hashed_reads->{headers} = \@headers;
    foreach my $read (@reads) {
        my $row;
        my @cells = split /,/, $read;
        for (my $i = 0; $i < scalar @headers; $i++) {
            $row->{$headers[$i]} = $cells[$i];
        }
        push (@{ $hashed_reads->{rows} }, $row);
    }

    return $hashed_reads;
}

1;

__END__
