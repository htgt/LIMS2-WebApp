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
              query_miseq_details
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use JSON;
use File::Find;
use Const::Fast;
use List::MoreUtils qw( uniq );

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
SELECT DISTINCT exp.id as experiment_id, wh.crispr_id, wh.design_id, output_well_id, start_well_id
FROM well_hierarchy wh
inner join experiments exp ON exp.crispr_id = wh.crispr_id and exp.design_id = wh.design_id
where wh.crispr_id is not null and wh.design_id is not null
EOT

#Crisprs and Designs are attached to processes at a much higher level.
#The second pr_out.well_id preserves the well id we started with. Using that we can trace exactly which well has lineage to the miseq classifications

const my $QUERY_MISEQ_SIBLINGS => <<'EOT';
WITH RECURSIVE descendants(process_id, input_well_id, output_well_id, start_well_id) AS (
    SELECT pr.id, pr_in.well_id, pr_out.well_id, pr_out.well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    WHERE pr_out.well_id IN (?)
    UNION
    SELECT pr.id, pr_in.well_id, pr_out.well_id, start_well_id
    FROM processes pr
    JOIN process_output_well pr_out ON pr_out.process_id = pr.id
    LEFT OUTER JOIN process_input_well pr_in ON pr_in.process_id = pr.id
    JOIN descendants ON descendants.output_well_id = pr_in.well_id
)
SELECT DISTINCT dest.input_well_id, dest.start_well_id, dest.process_id, well_in.name, plate_in.name,
well_out.id, plate_out.name, mp.id, me.experiment_id as exp, me.name, mwe.id as mwe_id, mwe.classification
FROM descendants dest
INNER JOIN wells well_in on input_well_id=well_in.id
INNER JOIN plates plate_in on well_in.plate_id=plate_in.id
INNER JOIN wells well_out on output_well_id=well_out.id
INNER JOIN plates plate_out on well_out.plate_id=plate_out.id
INNER JOIN miseq_plate mp on plate_out.id=mp.plate_id
INNER JOIN miseq_experiment me on mp.id=me.miseq_id and experiment_id IN (?)
INNER JOIN miseq_well_experiment mwe on mwe.well_id=well_out.id and me.id=mwe.miseq_exp_id
ORDER BY dest.start_well_id ASC
EOT

#Query is meant for finding Miseq calls from a sibling or distant-relation plate. Find classifications which stem from the same parent / grandparent well as the supplied plate (i.e. PIQ)
#This query first looks for parent wells then searches for child Miseq wells stemming from that parent 

sub query_miseq_details {
    my ($self, $plate_id) = @_;

$DB::single=1;
    my @ancestor_rows = @{ _find_inherited_experiment($self, $plate_id) };
    my @ancestor_headers = qw(
        exp_id
        crispr_id
        design_id
        well_id
        start_well_id
    );
    my @ancestor_results = _prepare_headers({ headers => \@ancestor_headers, results => \@ancestor_rows });

    my $experiments_str = _stringify_multiples('exp_id', @ancestor_results);
    my $ancestor_wells_str = _stringify_multiples('well_id', @ancestor_results);

    my @offspring_headers = qw(
        ancestor_well_id
        origin_well_id
        origin_process_id
        origin_well_name
        origin_plate_name
        miseq_well_id
        miseq_plate_name
        miseq_plate_details_id
        experiment_id
        miseq_experiment_name
        miseq_well_exp_id
        miseq_classification
    );
    my @offspring_rows = @{ _traverse_process_tree($self, $experiments_str, $ancestor_wells_str) };
    my @miseq_results = _prepare_headers({ headers => \@offspring_headers, results => \@offspring_rows });

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

sub _stringify_multiples {
    my ($key, @rows) = @_;

    my @values = map { $_->{$key} } @rows;
    my $str = join (',', uniq @values);

    return $str;
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
    my ($self, $experiments, $ancestors) = @_;
    
    my $query = $QUERY_MISEQ_SIBLINGS;
    return $self->schema->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->prepare_cached($query);
            $sth->bind_param(1, $ancestors); #Starts at 1 for some reason
            $sth->bind_param(2, $experiments);
            $sth->execute();
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
        @well_indexes{@well_names} = (0..$#well_names);
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

            my $quant = find_file($miseq, $index, $exp, "Quantification_of_editing_frequency.txt");
            if ($quant) {
                my $fh;
                open ($fh, '<:encoding(UTF-8)', $quant) or die "$!";
                my @lines = read_file_lines($fh);
                close $fh;

                $percentages->{$exp}->{wt} = ($lines[1] =~ qr/^,- Unmodified:(\d+)/)[0];
                $percentages->{$exp}->{nhej} = ($lines[2] =~ qr/^,- NHEJ:(\d+)/)[0];
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
    return $wells;
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

1;

__END__
