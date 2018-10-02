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
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use JSON;
use File::Find;
use Const::Fast;

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
