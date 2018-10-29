package LIMS2::WebApp::Controller::User::Miseq;
use Moose;
use namespace::autoclean;
use Data::UUID;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use LIMS2::Model::Util::BaseSpace;
use LIMS2::Model::Util::Miseq qw/wells_generator/;
use List::Util qw/max/;
use Text::CSV;
use Tie::IxHash;
use Try::Tiny;
use HTGT::QC::Util::FileAccessServer;
use WebAppCommon::Util::FarmJobRunner;
BEGIN { extends 'Catalyst::Controller' }

has file_api => (
    is         => 'ro',
    isa        => 'HTGT::QC::Util::FileAccessServer',
    lazy_build => 1,
    handles    => [qw/post_file_content/],
);

sub _build_file_api {
    return HTGT::QC::Util::FileAccessServer->new({
            file_api_url => $ENV{FILE_API_URL},
        });
}

has farm_job_runner => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::FarmJobRunner',
    lazy_build => 1,
);

sub _build_farm_job_runner {
    return WebAppCommon::Util::FarmJobRunner->new({ dry_run => 0 });
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
    $columns{Experiment} = qr/.+/xms; #anything goes, but must be something
    $columns{Gene}       = qr/^[A-Z0-9]+ # start with a gene symbol
                        (?:_.*)? # can be followed by an underscore and whatever
                        $/xms; 
    $columns{Crispr}     = qr/^[ACGT]{20}$/xms;
    $columns{Strand}     = qr/^[+-]$/xms;
    $columns{Amplicon}   = qr/^[ACGT]+$/ixms;
    $columns{min_index}  = qr/^\d+$/xms;
    $columns{max_index}  = qr/^\d+$/xms;
    $columns{HDR}        = qr/^[ACGT]*$/ixms;
    return \%columns;
}

sub _check_params {
    my ( $request, %required ) = @_;
    foreach my $key ( keys %required ) {
        my $spec = $required{$key};
        if ( not ref $spec ) {
            $spec = { type => 'param', message => $spec };
        }
        my $type = $spec->{type};
        if ( not defined $request->$type($key) ) {
            die $spec->{message};
        }
    }
    return;
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
    if ( @missing ) {
        die 'Missing required columns: ' . join(q/, /, @missing);
    }
    return;
}

sub _validate_value {
    my ( $row, $key, $validator, $line ) = @_;
    my $value = $row->{$key};
    if ( not $value =~ $validator ) {
        my $line_text = exists $row->{_rownum} ? " on line $row->{_rownum}" : q//;
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
    my $csv = Text::CSV->new({ binary => 1 });
    my $headers = $csv->getline($fh);
    $self->_validate_columns($headers);
    $csv->column_names( @{$headers} );
    my @rows = ();
    my $rownum = 1;
    while ( my $row = $csv->getline_hr($fh) ) {
        $row->{_rownum} = ++$rownum;
        $self->_validate_values( $row );
        push @rows, $row;
    }
    return \@rows;
}

sub _read_file {
    my ( $self, $file ) = @_;
    open my $fh, '<:encoding(utf8)', $file or die "Could not open spreadsheet: $!";
    my $exps = $self->_read_csv($fh);
    close $fh or die "Could not close spreadsheet: $!";
    return $exps;
}

sub _write_file {
    my ( $self, $exps ) = @_;
    my $csv = Text::CSV->new({ binary => 1, sep_char => q/,/, eol => "\n" });
    open my $fh, '>', \my $buffer or die "Could not write spreadsheet: $!";
    my @columns = $self->columns;
    $csv->print( $fh, \@columns );
    foreach my $exp ( @{$exps} ) {
        $csv->print( $fh, [map { $exp->{$_} } @columns] );
    }
    close $fh or die "Could not close spreadsheet: $!";
    return $buffer;
}

sub _get_plates {
    my ( $context, $samples, $experiments ) = @_;
    my ( $num_rows, $num_cols, $num_plates ) = ( 0, 0, 0 );
    my %barcodes = ();
    my $a = ord('A');
    foreach my $sample ( @{$samples} ) {
        my ( $name, $row, $col, $plate ) =
            $sample->sample_id =~ /^(([A-Z])([0-9]+)_([0-9]+))/xms;
        next if not $name;
        $num_rows = max $num_rows, (ord($row) - $a);
        $num_cols = max $num_cols, $col;
        $num_plates = max $num_plates, $plate;
        $barcodes{$name} = $sample->name;
    }
    my @plates   = ();
    foreach my $p ( 1 .. $num_plates ) {
        my @plate = ();
        foreach my $r ( 1 .. $num_rows ) {
            my @row = ();
            foreach my $c ( 1 .. $num_cols ) {
                my $name = sprintf("%s%02d_%d", chr($r + $a - 1), $c, $p);
                my $barcode = $barcodes{$name} // 0;
                my @exps = ();
                foreach my $exp ( @{$experiments} ) {
                    if ( ($barcode >= $exp->{min_index})
                        && ($barcode <= $exp->{max_index}) ) {
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


sub _get_dependency {
    my ( $self, @jobs ) = @_;
    return $self->farm_job_runner->dry_run ? [0] : \@jobs;
}

sub _process {
    my ( $self, $c ) = @_;

    my $bs = LIMS2::Model::Util::BaseSpace->new;
    my $jobid = Data::UUID->new->create_str;
    my $path = catfile($ENV{LIMS2_MISEQ_PROCESS_PATH}, $jobid);
    my $scripts = $ENV{LIMS2_MISEQ_SCRIPTS_PATH};

    my $plate = $c->request->param('plate');
    my $walkup = $c->request->param('walkup');
    my $experiments = $self->_read_file($c->request->upload('spreadsheet')->tempname);
    $c->stash->{experiments} = $experiments;

    die "'$plate' is not a valid name for a plate" if not $path =~ m/^\w+$/;
    
    my $destination = catfile($ENV{LIMS2_MISEQ_STORAGE_PATH}, $plate);
    if ( not mkdir $destination ) {
        $c->log->debug("Cannot store $plate: $!");
        die "Cannot store $plate";
    }
    
    my $project = LIMS2::Model::Util::BaseSpace->new->project($walkup);
    my @samples = $project->samples;
    my $plates = _get_plates($c, \@samples, $experiments);
    $c->stash->{plates} = $plates; 

    $c->stash->{job_id} = $jobid;
    $self->file_api->make_dir($path);
    $self->file_api->post_file_content(catfile($path, 'summary.csv'),
        $self->_write_file($experiments)); 
    $self->file_api->post_file_content(catfile($path, 'samples.txt'), 
        join("\n", map { $_->id } @samples));

    my $numsamples = scalar(@samples);
    my $downloader = catfile($scripts, 'bjob_download_basespace.sh');
    my $download_job = $self->farm_job_runner->submit({
            name     => "dl_${jobid}\[1-${numsamples}]%10",
            cwd      => $path,
            out_file => 'dl.%J.%I.out',
            err_file => 'dl.%J.%I.err',
            cmd      => [$downloader, $bs->{token}],
        });
    my $crispresso_job = $self->farm_job_runner->submit({
            name     => 'bsub_crispresso',
            cwd      => $path,
            out_file => 'cp.%J.out',
            err_file => 'cp.%J.err',
            cmd      => [catfile($scripts, 'bsub_crispresso_jobs.sh'),
                '--samples="summary.csv"',
                '--dir=.',
            ],
            dependencies => $self->_get_dependency($download_job),
        });
    my $move_job = $self->farm_job_runner->submit({
            name     => 'move_miseq_data',
            cwd      => $path,
            out_file => 'mv.%J.out',
            err_file => 'mv.%J.err',
            cmd      => [catfile($scripts, 'move_miseq_data.sh'), $destination],
            dependencies => $self->_get_dependency($crispresso_job),
        });

    $c->stash->{farm_job} = $move_job;
    return;
}

sub submit : Path('/user/miseq/submit') : Args(0) {
    my ( $self, $c ) = @_;
    try {
        foreach my $var ( qw/PROCESS_PATH SCRIPTS_PATH STORAGE_PATH/ ) {
            die "LIMS2_MISEQ_$var is not set" if not exists $ENV{"LIMS2_MISEQ_$var"};
        }
        _check_params($c->request,
            'plate'  => 'You must specify which MiSeq plate was sent',
            'walkup' => 'You must specify which MiSeq walkup contained the data',
            'spreadsheet' => {
                type    => 'upload',
                message => 'You must upload a CSV containing the MiSeq manifest',
            });
        $self->_process($c);
    }
    catch {
        $c->stash->{error_msg} = $_;
    };
    return;
}

sub import : Path('/user/miseq/import') : Args(0) {
    my ( $self, $c ) = @_;
    my $model = $c->model('Golgi');
    my $bs = LIMS2::Model::Util::BaseSpace->new;
    my @plates = $model->schema->resultset('Plate')->search(
        { type_id => 'MISEQ' },
        { columns => [qw/id name/] },
    );
    try {
        $c->stash->{plates} = [ sort { $b->id <=> $a->id } @plates ]; 
        $c->stash->{projects} = [ sort { $b->created cmp $a->created } $bs->projects ];
    }
    catch {
        $c->stash->{error_msg} = $_;
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;

