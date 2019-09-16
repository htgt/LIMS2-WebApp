package LIMS2::t::Model::Util::MiseqImport;
use base qw/Test::Class/;
use strict;
use warnings FATAL => 'all';
use Carp;
use File::Spec::Functions qw/catfile/;
use POSIX qw/strftime/;
use Test::Exception;
use Test::Most;
use Test::MockModule;
use Text::CSV;
use Text::ParseWords qw/shellwords/;
use LIMS2::Model::Util::MiseqImport;

sub mock_file_api {
    my @log      = ();
    my $file_api = Test::MockModule->new('WebAppCommon::Util::FileAccess');
    $file_api->mock(
        'make_dir',
        sub {
            my ( $self, $name ) = @_;
            push @log, $name;
        }
    );
    $file_api->mock(
        'post_file_content',
        sub {
            my ( $self, $name, $content ) = @_;
            push @log, { name => $name, content => $content };
        }
    );
    $file_api->mock( 'actions', sub { return @log; } );
    return $file_api;
}

sub mock_basespace_api {
    my %projects = map { $_->{Id} => $_ } @_;
    my %samples  = map { $_->{Id} => $_ }
      map { @{ $projects{$_}->{Samples} } }
      keys %projects;

    my $bs = Test::MockModule->new('LIMS2::Model::Util::BaseSpace');

    my %responders = (
        projects =>
          sub { my $id = shift; return @{ $projects{$id}->{Samples} }; },
        samples => sub { my $id = shift; return @{ $samples{$id}->{Files} }; },
    );

    $bs->mock(
        'get_all',
        sub {
            my ( $self, $request ) = @_;
            my ( $object, $id, $requested ) = split /\//, $request;
            return $responders{$object}( $id, $requested );
        }
    );

    return $bs;
}

sub parse_job {
    my ( $script_args_count, $dry_run ) = @_;

    # grab the part of the return from FarmJobRunner dry_run which is actually
    # the command run on the remote host
    my $cmd = ( split /;/, @{$dry_run}[-1], 3 )[-1];

    # parse the command line, excluding the initial bsub
    my ( undef, @args ) = shellwords($cmd);

    # remove the script and its arguments from the command line
    my ( $script, @script_args ) = splice @args, ( -1 - $script_args_count );
    return {
        bsub_args   => {@args},
        script      => $script,
        script_args => \@script_args
    };
}

sub get_default_bsub_options {
    my $runner = WebAppCommon::Util::FarmJobRunner->new( { dry_run => 1 } );
    return (
        '-G' => $runner->default_group,
        '-q' => $runner->default_queue,
        '-M' => $runner->default_memory,
        '-n' => $runner->default_processors,
        '-R' => 'select[mem>2000] rusage[mem=2000] span[hosts=1]',
    );
}

sub test_job {
    my ( $actual, $expected, $name ) = @_;
    my %options = ( get_default_bsub_options, %{ $expected->{bsub_options} } );
    my @expected_script_args = @{ $expected->{script_args} };
    my $job = parse_job( scalar(@expected_script_args), $actual );
    is_deeply( $job->{bsub_args}, \%options, $name );
    is(
        $job->{script},
        catfile( $ENV{LIMS2_MISEQ_SCRIPTS_PATH}, $expected->{script} ),
        $name
    );
    my @actual_script_args = @{ $job->{script_args} };
    is( scalar(@actual_script_args), scalar(@expected_script_args), $name );

    foreach my $expected_script_arg (@expected_script_args) {
        my $actual_script_arg = shift @actual_script_args;
        is( $actual_script_arg, $expected_script_arg, $name );
    }
}

sub create_spreadsheet {
    my ( $data, @columns ) = @_;
    if ( not @columns ) {
        @columns =
          qw/Experiment Gene Crispr Strand Amplicon min_index max_index HDR/;
    }
    my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
    my $output;
    open my $fh, '>', \$output or croak 'Could not create spreadsheet';
    $csv->print( $fh, \@columns );
    foreach my $exp ( @{$data} ) {
        $csv->print( $fh, [ map { $exp->{$_} } @columns ] );
    }
    close $fh or croak 'Could not close spreadsheet';
    return $output;
}

sub all_tests : Test(52) {
    my $importer = LIMS2::Model::Util::MiseqImport->new;
    $importer->farm_job_runner->dry_run(1);

    my $file_api      = mock_file_api;
    my $basespace_api = mock_basespace_api(
        {
            Id      => 42,
            Samples => [
                { Id => 421, SampleId => 'A01_1', Name => '1', },
                { Id => 422, SampleId => 'B01_1', Name => '2', },
            ],
        },
    );
    my @experiments = (
        {
            Experiment => 'Exp_01',
            Gene       => 'GENE1',
            Crispr     => 'ACGTACTGACTGACTGACTG',
            Amplicon   => 'ACTGACTGacgtactgactgactactgACTGACTG',
            Strand     => '+',
            min_index  => 1,
            max_index  => 96,
            HDR        => '',
        },
        {
            Experiment => 'Exp_02',
            Gene       => 'GENE2',
            Crispr     => 'ACGTACTGACTGACTGACTG',
            Amplicon   => 'ACTGACTGacgtactgactgactactgACTGACTG',
            Strand     => '+',
            min_index  => 97,
            max_index  => 192,
            HDR        => '',
        },
        {
            Experiment => 'Exp_03',
            Gene       => 'GENE3',
            Crispr     => 'ACGTACTGACTGACTGACTG',
            Amplicon   => 'ACTGACTGacgtactgactgactactgACTGACTG',
            Strand     => '+',
            min_index  => 1,
            max_index  => 96,
            HDR        => '',
        },
    );

    my $spreadsheet = create_spreadsheet( \@experiments );
    my ( $plate, $walkup ) = ( 'Miseq_Test_001', 42 );

    my $stash = $importer->process(
        plate       => $plate,
        walkup      => $walkup,
        spreadsheet => \$spreadsheet,
    );
    my $jobid = $stash->{job_id};
    my $date = strftime '%d-%m-%Y', localtime;
    my $path =
      catfile( $ENV{LIMS2_MISEQ_PROCESS_PATH}, join( q/_/, $plate, $jobid ) );
    my $dest_path = catfile( $ENV{LIMS2_MISEQ_STORAGE_PATH}, $plate );
    my $raw_path = catfile( $ENV{LIMS2_MISEQ_RAW_PATH},
        join( q/_/, $plate, "BS$walkup", $date ) );
    my @file_actions = $importer->file_api->actions;
    is( $file_actions[0], $dest_path );
    is( $file_actions[1], $raw_path );
    is( $file_actions[2], $path );
    is( $file_actions[3]->{name}, catfile( $path, 'summary.csv' ) );
    is( $file_actions[4]->{name}, catfile( $path, 'samples.txt' ) );
    is( $file_actions[4]->{content}, "421\n422" );

    test_job(
        $stash->{download_job},
        {
            bsub_options => {
                '-o'   => 'dl.%J.%I.out',
                '-e'   => 'dl.%J.%I.err',
                '-J'   => "dl_${jobid}[1-2]%10",
                '-cwd' => $path,
            },
            script      => 'bjob_download_basespace.sh',
            script_args => [ $ENV{BASESPACE_TOKEN} ],
        },
        'download job',
    );
    
    test_job(
        $stash->{move_job},
        {
            bsub_options => {
                '-o'   => 'mv.%J.out',
                '-e'   => 'mv.%J.err',
                '-J'   => 'move_miseq_data',
                '-w'   => 'exit(3)',
                '-cwd' => $path,
            },
            script      => 'move_miseq_data.sh',
            script_args => [
                '-p' => $dest_path,
                '-r' => $raw_path,
            ],
        },
        'move job',
    );

    my @crispresso_jobs = @{ $stash->{crispresso_jobs} };
    is( scalar(@crispresso_jobs), scalar(@experiments) );
    foreach my $job (@crispresso_jobs) {
        my $exp = shift @experiments;
        test_job(
            $job,
            {
                bsub_options => {
                    '-o' => "cp_$exp->{Experiment}.%J.%I.out",
                    '-e' => "cp_$exp->{Experiment}.%J.%I.err",
                    '-J' => sprintf( 'cp_%s[%d-%d]',
                        $exp->{Experiment}, $exp->{min_index},
                        $exp->{max_index} ),
                    '-cwd' => $path,
                    '-w'   => 'done(1)',
                },
                script      => 'bjob_crispresso.sh',
                script_args => [
                    '-g' => $exp->{Crispr},
                    '-a' => $exp->{Amplicon},
                    '-n' => $exp->{Experiment},
                ],
            },
            'CRISPResso ' . $exp->{Experiment},
        );
    }
    return;
}

sub test_csv_fails {
    my ( $importer, $validator, $description, $experiments, @columns ) = @_;
    my $spreadsheet = create_spreadsheet( $experiments, @columns );
    my ( $plate, $walkup ) = ( 'Miseq_Test_001', 42 );

    throws_ok {
        $importer->process(
            plate       => $plate,
            walkup      => $walkup,
            spreadsheet => \$spreadsheet,
        );
    } $validator, $description;
    return;
}


sub invalid_csv : Test(3) {
    my $importer = LIMS2::Model::Util::MiseqImport->new;
    $importer->farm_job_runner->dry_run(1);
    my $file_api      = mock_file_api;
    my $basespace_api = mock_basespace_api;

    my $experiment = {
        Experiment => 'Exp_01',
        Gene       => 'GENE1',
        Crispr     => 'ACGTACTGACTGACTGACTG',
        Amplicon   => 'ACTGACTGacgtactgactgactactgACTGACTG',
        Strand     => '+',
        min_index  => 1,
        max_index  => 96,
        HDR        => '',
    };

    test_csv_fails(
        $importer, 
        qr/not a valid value for Crispr/, 
        'CRISPR is wrong length',
        [ { %{$experiment}, Crispr => 'ACGT' } ], 
    );
    
    test_csv_fails(
        $importer,
        qr/not a valid value for Experiment/,
        'Experiment name is missing',
        [ { %{$experiment}, Experiment => '' } ],
    );

    test_csv_fails(
        $importer,
        qr/Missing required columns: Strand, max_index/,
        'Missing required columns',
        [ $experiment ],
        qw/Experiment Gene Crispr Amplicon min_index HDR/,
    );

    return;
}

1;

__END__

