package LIMS2::Model::Util::MiseqImport;
use Moose;
use namespace::autoclean;
use Bio::Perl qw/revcom_as_string/;
use Data::UUID;
use File::Spec::Functions qw/catfile/;
use LIMS2::Model::Util::BaseSpace;
use LIMS2::Model::Util::Miseq qw/wells_generator/;
use List::Util qw/max/;
use POSIX qw/strftime/;
use Text::CSV;
use Tie::IxHash;
use WebAppCommon::Util::FarmJobRunner;
with 'MooseX::Log::Log4perl';

has file_api => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::RemoteFileAccess',
    lazy_build => 1,
    handles    => [qw/post_file_content/],
);

sub _build_file_api {
    return WebAppCommon::Util::FileAccess->construct(
        { server => $ENV{LIMS2_FILE_ACCESS_SERVER}, } );
}

has farm_job_runner => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::FarmJobRunner',
    lazy_build => 1,
);

sub _build_farm_job_runner {
    return WebAppCommon::Util::FarmJobRunner->new( { dry_run => 0, server => $ENV{LIMS2_FILE_ACCESS_SERVER} } );
}

has basespace_api => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Util::BaseSpace',
    lazy_build => 1,
);

sub _build_basespace_api {
    return LIMS2::Model::Util::BaseSpace->new;
}

has spreadsheet_columns => (
    is         => 'ro',
    isa        => 'HashRef[RegexpRef]',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        get_rule => 'get',
        set_rule => 'set',
        columns  => 'keys'
    },
);

sub _build_spreadsheet_columns {
    tie my %columns, 'Tie::IxHash';
    $columns{experiment}        = qr/.+/xms;    #anything goes, but must be something
    $columns{gene}              = qr/^[A-Z0-9a-z]+
                                    (?:-[A-Z0-9a-z]+)? # some genes have hyphens
                                    (?:_.*)? # can be followed by an underscore and whatever
                                    $/xms;
    $columns{experiment_id}     = qr/^\d*$/xms;
    $columns{parent_plate_id}   = qr/^\d*$/xms;
    $columns{crispr}            = qr/^[ACGT]{20}(?:,[ACGT]{20})*$/ixms;
    $columns{strand}            = qr/^[+-]?$/xms;
    $columns{amplicon}          = qr/^[ACGT]+$/ixms;
    $columns{min_index}         = qr/^\d+$/xms;
    $columns{max_index}         = qr/^\d+$/xms;
    $columns{hdr}               = qr/^[ACGT]*$/ixms;
    $columns{offset_384}        = qr/^0|1$/xms;
    return \%columns;
}

sub _write_file {
    my ( $self, $exps ) = @_;

    my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
    open my $fh, '>', \my $buffer or die "Could not write spreadsheet: $!";
    my @columns = $self->columns;
    $csv->print( $fh, \@columns );
    foreach my $exp ( @{$exps} ) {
        $csv->print( $fh, [ map { $exp->{$_} } @columns ] );
    }
    close $fh or die "Could not close spreadsheet: $!";
    return $buffer;
}

sub _get_plates {
    my ( $samples, $experiments ) = @_;

    my ( $num_rows, $num_cols, $num_plates ) = ( 0, 0, 0 );
    my %barcodes = ();
    my $a        = ord('A');
    foreach my $sample ( @{$samples} ) {
        my ( $name, $row, $col, $plate ) =
          $sample->sample_id =~ /^(([A-Z])([0-9]+)_([0-9]+))/xms;
        next if not $name;
        $num_rows = max $num_rows, ( ord($row) - $a );
        $num_cols   = max $num_cols,   $col;
        $num_plates = max $num_plates, $plate;
        $barcodes{$name} = $sample->name;
    }
    my @plates = ();
    foreach my $p ( 1 .. $num_plates ) {
        my @plate = ();
        foreach my $r ( 1 .. $num_rows ) {
            my @row = ();
            foreach my $c ( 1 .. $num_cols ) {
                my $name = sprintf( "%s%02d_%d", chr( $r + $a - 1 ), $c, $p );
                my $barcode = $barcodes{$name} // 0;
                my @exps = ();
                foreach my $exp ( @{$experiments} ) {
                    my ( $min_index, $max_index ) = _get_correct_indexes($exp);
                    if (   ( $barcode >= $min_index )
                        && ( $barcode <= $max_index ) )
                    {
                        push @exps, $exp;
                    }
                }
                my $well = {
                    name    => $name,
                    barcode => $barcode,
                    exps    => \@exps,
                };
                push @row, $well;
            }
            push @plate, \@row;
        }
        push @plates, \@plate;
    }
    return \@plates;
}

sub _get_correct_indexes {
    my ( $exp ) = @_;
    my $min_index = $exp->{min_index};
    my $max_index = $exp->{max_index};
    if ( $exp->{offset_384} ) {
        $min_index += 384;
        $max_index += 384;
    }
    return ( $min_index, $max_index );
}

#this mostly exists to stop it breaking when running with dry_run
sub _get_dependency {
    my ( $self, @jobs ) = @_;
    return $self->farm_job_runner->dry_run ? [scalar(@jobs)] : \@jobs;
}

sub _submit_crispresso {
    my ( $self, $exp, $path, $crispresso_script, $dependencies ) = @_;

    my $id = $exp->{experiment};
    my @crisprs = split q/,/, uc( $exp->{crispr} );
    if ( $exp->{strand} eq '-' ) {
        foreach my $crispr (@crisprs) {
            $crispr = revcom_as_string($crispr);
        }
    }
    my $offset = $exp->{offset_384} ? 384 : 0;
    return $self->farm_job_runner->submit(
        {
            name => sprintf( 'cp_%s[%d-%d]',
                $id, $exp->{min_index}, $exp->{max_index} ),
            cwd          => $path,
            out_file     => "S%I_exp$id/job.out",
            err_file     => "S%I_exp$id/job.err",
            dependencies => $dependencies,
            cmd          => [
                $crispresso_script,
                '-g' => ( join q/,/, @crisprs ),
                '-a' => $exp->{amplicon},
                '-n' => $id,
                '-o' => $offset,
                '-e' => $exp->{hdr},
            ],
        }
    );
}

sub process {
    my ( $self, %params ) = @_;

    my $jobid  = Data::UUID->new->create_str;
    my $plate  = $params{plate};
    my $walkup = $params{walkup};
    my $path =
      catfile( $ENV{LIMS2_MISEQ_PROCESS_PATH}, join( q/_/, $plate, $jobid ) );
    my $scripts = $ENV{LIMS2_MISEQ_SCRIPTS_PATH};
    my $experiments = $self->_check_object($params{run_data});
    my $stash = { experiments => $experiments };

    die "'$plate' is not a valid name for a plate"   if not $plate  =~ m/^\w+$/;
    die "'$walkup' is not a valid walkup identifier" if not $walkup =~ m/^\d+$/;

    my $destination = catfile( $ENV{LIMS2_MISEQ_STORAGE_PATH}, $plate );
    my $date = strftime '%d-%m-%Y', localtime;
    my $raw_dest =
      catfile( $ENV{LIMS2_MISEQ_RAW_PATH}, "${plate}_BS${walkup}_$date" );

    $self->file_api->make_dir($destination);
    $self->file_api->make_dir($raw_dest);
    my $project = $self->basespace_api->project($walkup);
    my @samples = $project->samples;
    my $plates  = _get_plates( \@samples, $experiments );
    $stash->{plates} = $plates;

    $stash->{job_id} = $jobid;
    $self->file_api->make_dir($path);
    $self->file_api->post_file_content( catfile( $path, 'summary.csv' ),
        $self->_write_file($experiments) );
    $self->file_api->post_file_content(
        catfile( $path, 'samples.txt' ),
        join( "\n", map { $_->id } @samples )
    );

    my $numsamples   = scalar(@samples);
    my $downloader   = catfile( $scripts, 'bjob_download_basespace.sh' );
    my $download_job = $self->farm_job_runner->submit(
        {
            name     => "dl_${jobid}\[1-${numsamples}]%10",
            cwd      => $path,
            out_file => 'dl.%J.%I.out',
            err_file => 'dl.%J.%I.err',
            cmd      => [ $downloader, $self->basespace_api->{token} ],
        }
    );
    $stash->{download_job} = $download_job;

    my $crispresso_script = catfile( $scripts, 'bjob_crispresso.sh' );
    my @crispresso_jobs = map {
        $self->_submit_crispresso( $_, $path,
            $crispresso_script, $self->_get_dependency($download_job) )
    } @{$experiments};
    $stash->{crispresso_jobs} = \@crispresso_jobs;

    # Moving to warehouse fails as the farm doesn't have access
    my $move_job = $self->farm_job_runner->submit(
        {
            name         => 'move_miseq_data',
            cwd          => $path,
            out_file     => 'mv.%J.out',
            err_file     => 'mv.%J.err',
            dependencies => $self->_get_dependency(@crispresso_jobs),
            dep_type     => 'ended',
            cmd          => [
                catfile( $scripts, 'move_miseq_data.sh' ),
                '-p' => $destination,
                '-r' => $raw_dest,
            ],
        }
    );

    $stash->{move_job} = $move_job;
    return $stash;
}

sub _check_object {
    my ( $self, $data ) = @_;

    my @rows = ();
    foreach my $row (@{ $data }) {
        my @columns = keys %{ $row };
        $self->_validate_columns(@columns);
        $self->_validate_values($row);
        $self->_validate_indexes($row);
        push @rows, $row;
    }

    return \@rows;
}

sub _validate_columns {
    my ( $self, @given_columns ) = @_;
    my %columns = map { $_ => 1 } @given_columns;
    my @missing = ();
    foreach my $column ( $self->columns ) {
        if ( not exists $columns{$column} ) {
            push @missing, $column;
        }
    }
    if (@missing) {
        die 'Missing required columns: ' . join( q/, /, @missing );
    }
    return;
}

sub _validate_value {
    my ( $row, $key, $validator ) = @_;
    my $value = $row->{$key} // q//;
    if ( not $value =~ $validator ) {
        my $name = $row->{experiment};
        die "'$value' is not a valid value for $key:$name";
    }
    return;
}

sub _validate_values {
    my ( $self, $row ) = @_;
    foreach my $column ( $self->columns ) {
        _validate_value( $row, $column, $self->get_rule($column) );
    }
    return;
}

sub _validate_indexes {
    my ( $self, $row ) = @_;
    if ( $row->{min_index} > 384 or $row->{max_index} > 384 ) {
        die "Indexes should be below 384 for $row->{experiment}";
    }
    return;
}

1;
