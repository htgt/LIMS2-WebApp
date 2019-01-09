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
    isa        => 'HTGT::QC::Util::FileAccessServer',
    lazy_build => 1,
    handles    => [qw/post_file_content/],
);

sub _build_file_api {
    return HTGT::QC::Util::FileAccessServer->new(
        { file_api_url => $ENV{FILE_API_URL}, } );
}

has farm_job_runner => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::FarmJobRunner',
    lazy_build => 1,
);

sub _build_farm_job_runner {
    return WebAppCommon::Util::FarmJobRunner->new( { dry_run => 0 } );
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
    $columns{Experiment} = qr/.+/xms;    #anything goes, but must be something
    $columns{Gene} = qr/^[A-Z0-9]+ # start with a gene symbol
                        (?:_.*)? # can be followed by an underscore and whatever
                        $/xms;
    $columns{Crispr}    = qr/^[ACGT]{20}(?:,[ACGT]{20})*$/ixms;
    $columns{Strand}    = qr/^[+-]$/xms;
    $columns{Amplicon}  = qr/^[ACGT]+$/ixms;
    $columns{min_index} = qr/^\d+$/xms;
    $columns{max_index} = qr/^\d+$/xms;
    $columns{HDR}       = qr/^[ACGT]*$/ixms;
    return \%columns;
}

sub _validate_columns {
    my ( $self, $column_ref ) = @_;
    my %columns = map { $_ => 1 } @{$column_ref};
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
    my ( $row, $key, $validator, $line ) = @_;
    my $value = $row->{$key} // q//;
    if ( not $value =~ $validator ) {
        my $line_text =
          exists $row->{_rownum} ? " on line $row->{_rownum}" : q//;
        die "'$value' is not a valid value for $key$line_text";
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

sub _read_csv {
    my ( $self, $fh ) = @_;
    my $csv = Text::CSV->new( { binary => 1 } );
    my $headers = $csv->getline($fh);
    $self->_validate_columns($headers);
    $csv->column_names( @{$headers} );
    my @rows   = ();
    my $rownum = 1;
    while ( my $row = $csv->getline_hr($fh) ) {
        $row->{_rownum} = ++$rownum;
        $self->_validate_values($row);
        push @rows, $row;
    }
    return \@rows;
}

sub _read_file {
    my ( $self, $file ) = @_;
    open my $fh, '<:encoding(utf8)', $file
      or die "Could not open spreadsheet: $!";
    my $exps = $self->_read_csv($fh);
    close $fh or die "Could not close spreadsheet: $!";
    return $exps;
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
                    if (   ( $barcode >= $exp->{min_index} )
                        && ( $barcode <= $exp->{max_index} ) )
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

#this mostly exists to stop it breaking when running with dry_run
sub _get_dependency {
    my ( $self, @jobs ) = @_;
    return $self->farm_job_runner->dry_run ? [scalar(@jobs)] : \@jobs;
}

sub _submit_crispresso {
    my ( $self, $exp, $path, $crispresso_script, $dependencies ) = @_;
    my $id = $exp->{Experiment};
    my @crisprs = split q/,/, uc( $exp->{Crispr} );
    if ( $exp->{Strand} eq '-' ) {
        foreach my $crispr (@crisprs) {
            $crispr = revcom_as_string($crispr);
        }
    }
    return $self->farm_job_runner->submit(
        {
            name => sprintf( 'cp_%s[%d-%d]',
                $id, $exp->{min_index}, $exp->{max_index} ),
            cwd          => $path,
            out_file     => "cp_$id.%J.%I.out",
            err_file     => "cp_$id.%J.%I.err",
            dependencies => $dependencies,
            cmd          => [
                $crispresso_script,
                '-g' => ( join q/,/, @crisprs ),
                '-a' => $exp->{Amplicon},
                '-n' => $id,
            ],
        }
    );
}

sub _mkdir {
    return mkdir $_;
}

sub process {
    my ( $self, %params ) = @_;

    my $jobid  = Data::UUID->new->create_str;
    my $plate  = $params{plate};
    my $walkup = $params{walkup};
    my $path =
      catfile( $ENV{LIMS2_MISEQ_PROCESS_PATH}, join( q/_/, $plate, $jobid ) );
    my $scripts = $ENV{LIMS2_MISEQ_SCRIPTS_PATH};

    my $experiments = $self->_read_file( $params{spreadsheet} );
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

    my $move_job = $self->farm_job_runner->submit(
        {
            name     => 'move_miseq_data',
            cwd      => $path,
            out_file => 'mv.%J.out',
            err_file => 'mv.%J.err',
            cmd      => [
                catfile( $scripts, 'move_miseq_data.sh' ),
                '-p' => $destination,
                '-r' => $raw_dest,
            ],
            dependencies => $self->_get_dependency(@crispresso_jobs),
        }
    );

    $stash->{move_job} = $move_job;
    return $stash;
}

1;

