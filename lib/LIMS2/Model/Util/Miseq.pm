package LIMS2::Model::Util::Miseq;

use strict;
use warnings FATAL => 'all';
use Sub::Exporter -setup => {
    exports => [
        qw(
              miseq_well_processes
              wells_generator
              well_builder
              convert_index_to_well_name
              convert_well_name_to_index
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
              qc_relations
              query_miseq_tree_from_experiment
              get_alleles_freq_path
              get_csv_from_tsv_lines
              get_experiment_from_well 
              get_gene_symbols_from_well
              get_api
              classify_reads
              _get_miseq_data_from_well 
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use JSON;
use File::Find;
use Const::Fast;
use List::Util qw( sum first min sum0 );
use List::MoreUtils qw( uniq );
use SQL::Abstract;
use Bio::Perl;
use Text::CSV qw (csv);
use Try::Tiny;
use Carp;
use WebAppCommon::Util::FileAccess;
use Math::Round qw( round );
use Data::Dumper;
use DateTime::Format::ISO8601;

use LIMS2::Model::Util::WellName qw( convert_numeric_well_names_to_alphanumeric );

const my $QUERY_INHERITED_EXPERIMENT => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, start_well_id) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id, pr_out.well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     WHERE pr_out.well_id IN (select id from wells where plate_id = ?)
     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id, well_hierarchy.start_well_id
     FROM processes pr
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.input_well_id = pr_out.well_id
)
SELECT DISTINCT exp.id AS experiment_id, pc.crispr_id, pd.design_id, output_well_id, op.type_id, start_well_id, sw.name AS start_well_name
FROM well_hierarchy wh
LEFT JOIN process_crispr pc ON wh.process_id = pc.process_id
LEFT JOIN process_design pd ON wh.process_id = pd.process_id
LEFT JOIN experiments exp ON exp.crispr_id = pc.crispr_id AND exp.design_id = pd.design_id
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
    DEBUG("Querying miseq details");
    my ($self, $plate_id) = @_;

    my @ancestor_rows = @{ _find_inherited_experiment($self, $plate_id) };
    DEBUG("Ancestor rows: " . Dumper(@ancestor_rows));
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
    DEBUG("Ancestor results " . Dumper(@ancestor_results));
    my @epii_results = grep { $_->{type_id} eq 'EP_PIPELINE_II' && $_->{exp_id} } @ancestor_results;
    my @epii = uniq map { $_->{exp_id} } @epii_results;
    my @parents = uniq map { $_->{well_id} } grep { $_->{type_id} ne 'EP_PIPELINE_II' } @ancestor_results;

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
    DEBUG("Offspring rows: " . Dumper(@offspring_rows));
    my @miseq_results = _prepare_headers({ headers => \@offspring_headers, results => \@offspring_rows });

    map { $_->{sibling_origin_wells} = $parent_mapping->{ $_->{origin_well_id} } } @miseq_results;

    DEBUG("Miseq details: " . Dumper(@miseq_results));

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
    # Converts to "WHERE experiment_id IN (id1, id2, ...)", for the IDs in $experiments.
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
        if ($result->{miseq_well_exp_classification} ne 'Not Called' && $result->{miseq_well_exp_classification} ne 'Mixed') {
            my $class_details = {
                classification  => $result->{miseq_well_exp_classification},
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

const my $QUERY_MISEQ_TREE_BY_EXPERIMENT_ID => <<'EOT';
WITH RECURSIVE well_hierarchy(process_id, input_well_id, output_well_id, start_well_id) AS (
     SELECT pr.id, pr_in.well_id, pr_out.well_id, pr_out.well_id
     FROM processes pr
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     WHERE pr_out.well_id IN (
        SELECT w.id
        FROM process_design pd
        INNER JOIN process_crispr pc ON pc.process_id=pd.process_id
        INNER JOIN process_output_well pow ON pow.process_id=pd.process_id
        INNER JOIN wells w ON w.id=pow.well_id
        INNER JOIN plates p ON p.id=w.plate_id
        INNER JOIN experiments exp ON exp.design_id=pd.design_id AND exp.crispr_id=pc.crispr_id
        WHERE exp.id = ?
     )
     UNION
     SELECT pr.id, pr_in.well_id, pr_out.well_id, well_hierarchy.start_well_id
     FROM processes pr
     JOIN process_output_well pr_out ON pr_out.process_id = pr.id
     LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
     JOIN well_hierarchy ON well_hierarchy.output_well_id = pr_in.well_id
)
SELECT DISTINCT output_well_id, input_well_id, inp.type_id, start_well_id, mwe.classification, me.name, me.experiment_id
FROM well_hierarchy wh
INNER JOIN wells ow ON ow.id=output_well_id
INNER JOIN plates op ON ow.plate_id=op.id
INNER JOIN wells inw ON inw.id=input_well_id
INNER JOIN plates inp ON inp.id=inw.plate_id
INNER JOIN wells sw ON sw.id=start_well_id
INNER JOIN miseq_well_experiment mwe ON mwe.well_id=output_well_id
INNER JOIN miseq_experiment me ON mwe.miseq_exp_id=me.id
WHERE op.type_id = 'MISEQ' AND mwe.classification NOT IN ('Not Called','Mixed')
AND me.experiment_id = ?
EOT

sub query_miseq_tree_from_experiment {
    my ($c, $experiment_id) = @_;

    my @results = @{ _query_miseq_tree_by_exp($c->model('Golgi'), $experiment_id) };

    my @headers = qw(
        miseq_well_id
        parent_well_id
        parent_plate_type
        origin_well_id
        classification
        miseq_experiment_name
        experiment_id
    );
    my @miseq_relations;
    foreach my $miseq_well_relation (@results) {
        my %mapping;
        @mapping{@headers} = @{ $miseq_well_relation };
        push @miseq_relations, \%mapping;
    }

    return @miseq_relations;
}

sub _query_miseq_tree_by_exp {
    my ($self, $experiment_id) = @_;

    my $query = $QUERY_MISEQ_TREE_BY_EXPERIMENT_ID;
    return $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare_cached( $query );
            $sth->execute( $experiment_id, $experiment_id );
            $sth->fetchall_arrayref;
        }
    );
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

#Find all Classified Miseq well experiments related to an experiment ID
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

    if ($index < 1 or $index > 384) {
        return '';
    }

    my @wells = wells_generator();
    my $name = $wells[$index - 1];

    return $name;
}

sub convert_well_name_to_index {
    my $well_name = shift;

    my @wells = wells_generator();
    my $index = first { $wells[$_] eq $well_name } 0..$#wells;

    if (! defined $index) {
        return 0;
    }

    return $index + 1;
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

sub generate_summary_data {
    my ($c, $plate_id, $miseq_id) = @_;

    my $overview;
    my $ranges;
    my $wells;
    my $index;
    my $converter = wells_generator(1);
    my @miseq_exp_rs = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({ miseq_id => $miseq_id });
    foreach my $miseq_exp (@miseq_exp_rs) {

        my $exp_name = $miseq_exp->{name};
        my @well_exps = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $miseq_exp->{id} });
        my @indexes;

        foreach my $well_exp (@well_exps) {
            my $percentages;
            my $details;
            $index = $converter->{$well_exp->{well_name}};

            push (@indexes, $index);

            $details->{class}       = $well_exp->{classification};
            $details->{status}      = $well_exp->{status};
            $details->{frameshift}  = $well_exp->{frameshifted};

            my $total = $well_exp->{total_reads};
            my $nhej = $well_exp->{nhej_reads};
            my $hdr = $well_exp->{hdr_reads};
            my $mixed = $well_exp->{mixed_reads};
            my $wt;
            if (defined $total and defined $nhej and defined $hdr and defined $mixed) {
                $wt = $total - $nhej - $hdr - $mixed;
            } else {
                warn "\nCorrupt data for experiment: $exp_name, in well index: $index \n";
                next;
            }
            $percentages->{wt}   = qq/$wt/;
            $percentages->{nhej} = qq/$nhej/;
            $percentages->{hdr}  = qq/$hdr/;
            $percentages->{mix}  = qq/$mixed/;

            $wells->{sprintf("%02d", $index)}->{percentages}->{$exp_name} = $percentages;
            $wells->{sprintf("%02d", $index)}->{details}->{$exp_name} = $details;
            push ( @{$wells->{sprintf("%02d", $index)}->{gene}}, $miseq_exp->{gene});
            push ( @{$wells->{sprintf("%02d", $index)}->{experiments}}, $exp_name);
        }

        if ( !@indexes ) {
            warn "\n Empty experiment: $exp_name \n";
            next;
        }
        @indexes = sort { $a <=> $b } @indexes;
        my $range = $indexes[0] . '-' . $indexes[-1];
        $ranges->{$miseq_exp->{name}} = $range;

        my @gene;
        push @gene, $miseq_exp->{gene};
        $overview->{$miseq_exp->{name}} = \@gene;
    }

    for (my $i = 1; $i < 385; $i++) {
        unless ($wells->{sprintf("%02d", $i)}){
            $wells->{sprintf("%02d", $i)}->{percentages} = undef;
            $wells->{sprintf("%02d", $i)}->{details} = undef;

            $wells->{sprintf("%02d", $i)}->{gene} = [];
            $wells->{sprintf("%02d", $i)}->{experiments} = [];
            }
    }
    return {
        ranges      => $ranges,
        overview    => $overview,
        wells       => $wells
    };
}


#THIS SUB IS NOT USED ANYMORE. IT WAS REPLACED AFTER THE DATA WAS MIGRATED FROM THE LOCAL FILES TO THE DATABASE.
sub generate_summary_data_old {
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
            #barcode    => [$ug->create_str(), $ug->create_str()],
            percentages => $percentages,
            details     => $details,
        };
    }
    return $wells;
}

sub read_alleles_frequency_file {
    my ($api, $miseq, $index, $exp, $threshold, $threshold_as_percentage) = @_;

    $threshold = $threshold ? $threshold : 0;

    my $base = $ENV{LIMS2_RNA_SEQ};
    my $path = get_alleles_freq_path($base, $miseq, $exp, $index, $api);
    if (! $path) {
        croak 'No path available';
    }
    my @content = $api->get_file_content($path);
    if (scalar @content < 2) {
        croak 'No data in file';
    }
    my @lines = get_csv_from_tsv_lines(@content);
    if ($threshold_as_percentage) {
        @lines = _find_read_quantification_gt_threshold($threshold, @lines);
    } elsif ($threshold != 0) {
        my $line_limit = min($threshold, (scalar(@lines) - 1));
        @lines = @lines[0..$line_limit];
    }

    return @lines;
}

sub get_alleles_freq_path {
    my ($base, $miseq, $exp, $index, $api) = @_;
    my $start = "${base}/${miseq}/S${index}_exp${exp}/CRISPResso_on";
    my $filename = "Alleles_frequency_table.txt";
    my $index_384 = $index + 384;
    my @possible_paths = (
        "${start}_${index}_S${index}_L001_R1_001_${index}_S${index}_L001_R2_001/$filename",
        "${start}_${index_384}_S${index_384}_L001_R1_001_${index_384}_S${index_384}_L001_R2_001/$filename",
        "${start}_${index}_S${index}_L001_R1/$filename",
        "${start}_${index_384}_S${index_384}_L001_R1/$filename"
    );
    foreach my $path (@possible_paths) {
        if ($api->check_file_existence($path)) {
            return $path;
        }
    }
    return 0;
}

sub get_csv_from_tsv_lines {
    my @tsv_lines = @_;
    my @csv_lines;
    foreach my $line (@tsv_lines) {
        chomp $line;
        push(@csv_lines, join(',', split(/\t/,$line)));
    }
    return @csv_lines;
}

#The method beloow works, but does not have refference sequences. Therefore, for the time it is not used.
sub read_alleles_frequency_file_db {
    my ($c, $miseq_well_experiment_hash, $threshold, $threshold_as_percentage) = @_;
    my $frequency_rs = $c->model('Golgi')->schema->resultset('MiseqAllelesFrequency')->search(
         { miseq_well_experiment_id => $miseq_well_experiment_hash->{id} }
    );
    my $alleles_count = $frequency_rs->count;
    my @lines;
    push @lines ,'Aligned Sequence,NHEJ,Unmodified,HDR,Deleted,Inserted,Mutated,Reads,%Reads';
    if ($alleles_count > 0) {
        while (my $freq_rs = $frequency_rs->next){
            my $freq_hash = $freq_rs->as_hash;
            $freq_hash->{reference_sequence} = $freq_rs->reference_sequence;
            $freq_hash->{quality_score} = $freq_rs->quality_score;
            my $sum = $freq_hash->{n_reads};
            my $percentage = $sum / $miseq_well_experiment_hash->{total_reads} * 100.0;
            push @lines,
                $freq_hash->{aligned_sequence}   .",".   $freq_hash->{nhej}                       .",".
                $freq_hash->{unmodified}         .",".   $freq_hash->{hdr}                        .",".
                $freq_hash->{n_deleted}          .",".   $freq_hash->{n_inserted}                 .",".
                $freq_hash->{n_mutated}          .",".   $freq_hash->{n_reads}                    .",".
                $percentage;
        }
    }
    else {
        print "No alleles frequency data found in the database.";
    }

    my $res;
    if ($threshold_as_percentage) {
        @lines = _find_read_quantification_gt_threshold($threshold, @lines);
    } elsif ($threshold != 0) {
        @lines = @lines[0..$threshold];
    }
    return @lines;
}

sub _find_read_quantification_gt_threshold {
    my ($threshold, @lines) = @_;

    my @relevant_reads;
    my $count = 0;
    my $read_perc = 100;

    while ($read_perc > $threshold) {
        push @relevant_reads, $lines[$count];
        $count++;
        if ($lines[$count]) {
            my @cells = split /,/, $lines[$count];
            $read_perc = $cells[-1];
        } else {
            $read_perc = 0;
        }
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

sub qc_relations {
    my ($c, $well) = @_;

    my @related_qc = query_miseq_details($c->model('Golgi'), $well->plate_id);

    @related_qc = grep { $_->{origin_well_id} eq $well->id } @related_qc;
    my $relations;
    foreach my $qc (@related_qc) {
        push (@{$relations->{$qc->{experiment_id}}->{$qc->{miseq_plate_name}}}, $qc);
    }
    return;
}

sub miseq_genotyping_info {
    my ($c, $well) = @_;

    INFO("Getting clone genotyping info for well: $well");

    my $experiments = {
        well_id             => $well->id,
        barcode             => $well->barcode,
        well_name           => $well->name,
        plate_name          => $well->plate_name,
        cell_line           => $well->first_cell_line->name,
        species             => _get_species_from_well($well),
        gene_id             => _get_gene_id_from_well($well),
        gene                => get_gene_symbols_from_well($c, $well),
        clone_id            => "$well",  # Well object resolves to the well-id (aka clone-id) when stringified.
        design_id           => _get_design_id_from_well($well),
        design_type         => _get_design_type_from_well($well),
        oligos              => _get_oligo_from_well($well),
        hdr_template        => _get_hdr_template_from_well($well),
        crispr              => _get_crispr_from_well($well),
        miseq               => _get_miseq_data_from_well($c->model("Golgi"), $well),
    };

    return $experiments;
}

sub _get_species_from_well {
    my $well = shift;
    my $design = $well->design;
    unless(defined $design){
        die "No design associated with well. Looks like the programmer doesn't understand the data model yet.";
    }
    return $design->species_id;
}

sub _get_gene_id_from_well {
    my $well = shift;
    my @gene_ids = $well->design->gene_ids;
    my $number_of_genes = scalar @gene_ids;
    if ($number_of_genes != 1) {
        LIMS2::Exception::Implementation->throw(
            "Current implementation of _get_gene_id_from_well assumes"
	    . " only one gene associated with each well, but $number_of_genes found: "
	    . Dumper(@gene_ids)
        );
    }
    return $gene_ids[0];
}

sub get_gene_symbols_from_well {
    my ($c, $well) = @_;
    my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };
    my @gene_symbols = $well->design->gene_symbols($gene_finder);
    return join(", ", @gene_symbols);
}

sub _get_design_id_from_well {
    my $well = shift;
    return $well->design->id;
}

sub _get_oligo_from_well {
    my $well = shift;
    my $oligos = $well->design->as_hash->{'oligos'};
    for my $oligo (@$oligos) {
        $oligo->{'sequence_in_5_to_3_prime_orientation'} = _calculate_sequence_in_5_to_3_prime_orientation (
            $oligo->{'seq'},
            $oligo->{'type'}
        )
    }
    return $oligos;
}

sub _calculate_sequence_in_5_to_3_prime_orientation {
    my ($stored_sequence, $primer_type) = @_;
    if (grep $_ eq $primer_type, ("INF", "EXF")) {
        return $stored_sequence;
    }
    if (grep $_ eq $primer_type, ("INR", "EXR")) {
        return reverse_complement_as_string($stored_sequence);
    }
    die "Unrecognised primer type: $primer_type";
}

sub _get_design_type_from_well {
    my $well = shift;
    return $well->design->design_type_id;
}

sub _get_hdr_template_from_well {
    my $well = shift;
    return $well->design->hdr_amplicon;
}

sub _get_crispr_from_well {
    my $well = shift;
    my $crispr_info = $well
      ->ancestors
      ->find_process_of_type($well, "ep_pipeline_ii")
      ->process_crispr
      ->crispr
      ->as_hash()
    ;
    $crispr_info->{locus}{chr_strand} = _reformat_strand_info_into_plus_minus_form(
        $crispr_info->{locus}{chr_strand}
    );
    return $crispr_info;
}

sub _reformat_strand_info_into_plus_minus_form {
    my $input_strand_info = shift;
    if ($input_strand_info eq "1") {
	return "+";
    }
    if ($input_strand_info eq "-1") {
	return "-";
    }
    die "Unknown strand type: $input_strand_info";
}

sub _get_miseq_data_from_well {
    my ($model, $well) = @_;
    my $plate = $well->plate;
    my $entry = _get_entry_from_list("clone-miseq-map.tsv", $plate->name, $well->name);
    if (defined $entry) {
        DEBUG("It's defined");
        my @miseq_well_experiments = $model->schema->resultset('MiseqWellExperiment')->search(
            {
                'miseq_exp.name' => $entry->{"miseq_experiment_name"},
                'well.name' => convert_numeric_well_names_to_alphanumeric($entry->{"miseq_well"}),
                'plate.name' => $entry->{"miseq_plate"},
            },
            {prefetch => ['miseq_exp', 'well', { well => 'plate'}]},
        );
        if (scalar(@miseq_well_experiments) != 1) {die "There can only be one..."};
        my $miseq_well_experiment = $miseq_well_experiments[0];
        my $indel_data = _get_indel_data_from_miseq_well_experiment($miseq_well_experiment);
        my $allele_data = _get_allele_data_from_miseq_well_experiment($miseq_well_experiment);
        return {
            "data" => {
                "miseq_plate" => $entry->{"miseq_plate"},
                "miseq_well" => convert_numeric_well_names_to_alphanumeric($entry->{"miseq_well"}),
                "experiment_name" => $miseq_well_experiment->experiment,
                "total_reads" =>  $miseq_well_experiment->total_reads,
                "classification" => $miseq_well_experiment->class,
                "indel_data" => $indel_data,
                "allele_data" => $allele_data,
            },
        };
    }
    my $missing_entry = _get_entry_from_list("missing-miseq.tsv", $plate->name, $well->name);
    if (defined $missing_entry) {
        DEBUG("Looks like Miseq data is missing for $well");
        return {
            "error" => $missing_entry->{"note"},
        };
    }

    my $piq_plate_well = _get_piq_plate_well_from_well($well);
    if (! defined $piq_plate_well) {
        return undef;
    }
    DEBUG("Parent plate well id: " .  $piq_plate_well->id);
    my $miseq_plate_well = _get_miseq_well_from_piq_well($piq_plate_well);
    if (! defined $miseq_plate_well) {
        return undef;
    }
    DEBUG("Miseq well: $miseq_plate_well");
    DEBUG("Miseq well id: " .  $miseq_plate_well->id);
    my $experiment_in_well =  get_experiment_from_well($well);
    my @miseq_well_experiments = $miseq_plate_well
        ->miseq_well_experiments
	->search(
            {'miseq_exp.experiment_id' => $experiment_in_well->id},
            {prefetch => ['miseq_exp']},
        )
    ;
    if (scalar @miseq_well_experiments == 0) {
        DEBUG("No miseq_well_experiments found.");
        return undef;
    }
    my $miseq_well_experiment = undef;
    if (scalar @miseq_well_experiments > 1) {
        my @miseq_well_experiment_ids = map {$_->id} @miseq_well_experiments;
        DEBUG("Found multiple miseq-well-experiments. IDs: " . Dumper(@miseq_well_experiment_ids));
        my @miseq_well_experiments_for_parent_plate = grep {
            (defined $_->miseq_exp->parent_plate_id) && ($_->miseq_exp->parent_plate_id == $piq_plate_well->plate->id)
        } @miseq_well_experiments;
        if (scalar @miseq_well_experiments_for_parent_plate == 1) {
            $miseq_well_experiment = $miseq_well_experiments_for_parent_plate[0];
            DEBUG("Disambiguated by checking parent plate: " . $miseq_well_experiment->id);
        } else {
            die "Expected at most one miseq well experiment, but found experiments with ID: " . Dumper(@miseq_well_experiment_ids);
        }
    } else {
        $miseq_well_experiment = $miseq_well_experiments[0];
    }
    my $indel_data = _get_indel_data_from_miseq_well_experiment($miseq_well_experiment);
    my $allele_data = _get_allele_data_from_miseq_well_experiment($miseq_well_experiment);
    return {
        "data" => {
            "miseq_plate" => $miseq_plate_well->plate->name,
            "miseq_well" => $miseq_plate_well->name,
            "experiment_name" => $miseq_well_experiment->experiment,
            "total_reads" =>  $miseq_well_experiment->total_reads,
            "classification" => $miseq_well_experiment->class,
            "indel_data" => $indel_data,
            "allele_data" => $allele_data,
        },
    };

}

sub _get_entry_from_list {
    my ($tsv_file, $plate_name, $well_name) = @_;
    my $clone_miseq_mapping = csv(
        in => "bin/clone_data/$tsv_file",
        headers => "auto",
        sep_char => "\t",
        filter => {
            fp_plate => sub {$_ eq $plate_name},
            fp_well => sub {$_ eq $well_name}
        }
    );
    DEBUG(Dumper($clone_miseq_mapping));
    if (scalar(@{$clone_miseq_mapping}) > 1) {
        die "There should only be one entry on the list but found two for ${plate_name}_${well_name}";
    } elsif (scalar(@{$clone_miseq_mapping}) == 1) {
        DEBUG("Found an entry");
        my $entry = $clone_miseq_mapping->[0];
        DEBUG(Dumper($entry));
        my $someEmpty = grep { !defined($_) or $_ eq '' } values %{$entry};
        DEBUG($someEmpty);
        if ($someEmpty) {die "All entries should be non-empty";}
        return $entry;
    } else {
        DEBUG("Didn't find an entry for ${plate_name}_${well_name}");
        return undef;
    }
}

sub get_experiment_from_well {
    my $well = shift;
    my @experiments_in_well = $well
        ->result_source
        ->schema
        ->resultset('Experiment')
        ->search({
            'design_id' => $well->design->id,
            'crispr_id' => _get_crispr_from_well($well)->{'id'},
        })
    ;
    if (scalar @experiments_in_well == 0) {
        die "No experiment found for well with id: " . $well->id;
    }
    if (scalar @experiments_in_well > 1) {
        die "Multiple experiments found for well with id: " . $well->id;
    }
    my $experiment_in_well = $experiments_in_well[0];
    DEBUG("Got experiment with ID: " . $experiment_in_well->id);
    return $experiment_in_well;
}

sub _get_miseq_well_from_piq_well {
    my $piq_plate_well = shift;
    my @miseq_plate_wells = $piq_plate_well
      ->descendants_of_type('MISEQ')
    ;
    if (scalar @miseq_plate_wells == 0) {
        DEBUG("Can't find miseq-plate well for PIQ plate well with ID: " . $piq_plate_well->id);
        return undef;
    }
    if (scalar @miseq_plate_wells > 1) {
        die "Assuming only one MISEQ plate, but found: " . scalar @miseq_plate_wells;
    }
    return $miseq_plate_wells[0];
}

sub _get_piq_plate_well_from_well {
    my $well = shift;
    my @piq_plate_wells = $well
      ->descendants_of_type('PIQ')
    ;
    if (scalar @piq_plate_wells == 0) {
        DEBUG("Can't find PIQ-plate well for well with ID: " . $well->id);
        return undef;
    }
    if (scalar @piq_plate_wells > 1) {
        DEBUG(
            "Found multiple PIQ-plate wells for well with Id: "
            . $well->id
            . ". Choosing most recent."
        );
        my $iso8601 = DateTime::Format::ISO8601->new();
        my @piq_plate_wells_in_date_order = sort {
            DateTime->compare(
                $iso8601->parse_datetime($a->created_at),
                $iso8601->parse_datetime($b->created_at)
            )
        } @piq_plate_wells;
        return pop @piq_plate_wells_in_date_order;
    }
    return $piq_plate_wells[0];

}

sub _get_indel_data_from_miseq_well_experiment {
    my $miseq_well_experiment = shift;
    my @indel_data = map {
        {
	    "indel" => $_->indel_size,
	    "frequency" => $_->frequency,
        }
    } $miseq_well_experiment->indel_histograms;
    push @indel_data, _calculate_zero_indel_frequency($miseq_well_experiment, @indel_data);
    return \@indel_data;
}

sub _get_allele_data_from_miseq_well_experiment {
    my $miseq_well_experiment = shift;
    my $total_reads = $miseq_well_experiment->total_reads;
    my @allele_data = map {
        {
            "aligned_sequence" => $_->aligned_sequence,
            "nhej" => $_->nhej,
            "unmodified" => $_->unmodified,
            "hdr" => $_->hdr,
            "n_deleted" => $_->n_deleted,
            "n_inserted" => $_->n_inserted,
            "n_mutated" => $_->n_mutated,
            "n_reads" => $_->n_reads,
            "percentage_reads" => _calculate_percentage_reads($_->n_reads, $total_reads),
        }
    } $miseq_well_experiment->miseq_alleles_frequencies;
    return \@allele_data;

}

sub _calculate_zero_indel_frequency {
    my ($miseq_well_experiment, @indel_data) = @_;
    my $total_non_zero_reads = sum0 (map {$_->{"frequency"}} @indel_data);
    return {
        "indel" => 0,
        "frequency" => $miseq_well_experiment->total_reads - $total_non_zero_reads,
    };
}

sub _calculate_percentage_reads {
    my ($n_reads, $total_reads) = @_;
    if ($total_reads == 0) { die "Total allele reads is unexpectedly zero." };
    # We want the percentage to two decimal places.
    return round( $n_reads / $total_reads * 10_000 ) / 100;
}

sub get_api {
    my $base = shift;
    if (-e $base) {
        return WebAppCommon::Util::FileAccess->construct();
    } else {
        return WebAppCommon::Util::FileAccess->construct({server => $ENV{LIMS2_FILE_ACCESS_SERVER}});
    }
}

sub classify_reads {
    my ($allele_data, $indel_data) = @_;
    if (_is_wildtype($allele_data, $indel_data)) {return "WT"};
    if (_is_ko_hom($indel_data)) {return "K/O Hom"};
    if (_is_ko_het($indel_data)) {return "K/O Het"};
    return;
}

sub _is_wildtype {
    my ($allele_data, $indel_data) = @_;
    DEBUG("All the indel data: " . Dumper( $indel_data));
    my $most_common_allele = (sort { $b->{n_reads} <=> $a->{n_reads} } @$allele_data)[0];
    unless (defined $most_common_allele) {die "Looks like there aren't any alleles"};
    my $total_number_of_indels = sum map {$_->{frequency}} @$indel_data;
    unless (defined $total_number_of_indels) {die "Looks like there are no indels"};
    my @zero_indels = (grep { $_->{indel} ==  0} @$indel_data);
    DEBUG("The zero indels: " . Dumper(@zero_indels));
    my $number_of_zero_indels = undef;
    my $ratio_of_zero_indels = undef;
    if (scalar  @zero_indels == 1) {
        $number_of_zero_indels = $zero_indels[0]->{frequency};
        $ratio_of_zero_indels = $number_of_zero_indels / $total_number_of_indels;
    }
    DEBUG("Ratio of zero indels:" . Dumper($ratio_of_zero_indels));
    if (defined($ratio_of_zero_indels) && $ratio_of_zero_indels > 0.98 && $most_common_allele->{unmodified} == 1) {return 1};
    return 0;

}

sub _is_ko_hom {
    my $indel_data = shift;
    my $total_number_of_indels = sum map {$_->{frequency}} @$indel_data;
    unless (defined $total_number_of_indels) {die "Looks like there are no indels"};
    my @sorted = sort { $b->{frequency} <=> $a->{frequency} } @$indel_data;
    my $most_frequent_indel = $sorted[0];
    my $number_of_most_frequent = $most_frequent_indel->{frequency};
    my $ratio_of_most_frequent = $number_of_most_frequent / $total_number_of_indels;
    my $indel_of_most_frequent = $most_frequent_indel->{indel};
    if ($ratio_of_most_frequent > 0.98 && $indel_of_most_frequent != 0 && $indel_of_most_frequent % 3 != 0) {return 1};
    return 0;
}

sub _is_ko_het {
    my $indel_data = shift;
    unless (scalar @$indel_data > 1) {return 0};
    my $total_number_of_indels = sum map {$_->{frequency}} @$indel_data;
    my @sorted = sort { $b->{frequency} <=> $a->{frequency} } @$indel_data;
    my $most_frequent_indel = $sorted[0];
    my $next_most_frequent_indel = $sorted[1];
    unless ($most_frequent_indel->{indel} == 0 || $next_most_frequent_indel->{indel} == 0) {return 0};
    unless ($most_frequent_indel->{indel} % 3 != 0 || $next_most_frequent_indel->{indel} % 3 != 0) {return 0};
    my $ratio_of_two_most_frequent =
        ($most_frequent_indel->{frequency} + $next_most_frequent_indel->{frequency})
        / $total_number_of_indels;
    unless ($ratio_of_two_most_frequent > 0.98) {return 0};
    my $ratio_of_most_frequent_to_next_most_frequent =
        $most_frequent_indel->{frequency}
        / ($most_frequent_indel->{frequency} + $next_most_frequent_indel->{frequency});
    unless ($ratio_of_most_frequent_to_next_most_frequent <= 0.6) {return 0};
    return 1;
}

1;

__END__
