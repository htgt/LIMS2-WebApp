package LIMS2::QC::KillQCFarmJobs;

use Moose;
use YAML::Any;
use List::Util qw( min );
use IPC::Run ();
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

has qc_run_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has config => (
    is       => 'ro',
    isa      => 'HTGT::QC::Config',
    required => 1
);

sub kill_unfinished_farm_jobs{
    my $self = shift;

    my $job_id_file = $self->config->basedir->subdir( $self->qc_run_id )->file( "lsf.job_id" );
    my $job_id_fh = $job_id_file->openr();

    my @job_ids;
    while( my $job_id = $job_id_fh->getline() ) {
        chomp( $job_id );
        push @job_ids, $job_id;
    }

    run_cmd(
        'bsub',
        'bkill',
        @job_ids
    );

    return \@job_ids;
}

sub run_cmd {
    my @cmd = @_;

    my $output;
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        die "Command failed: $err";
    }

    chomp $output;
    return  $output;
}
__PACKAGE__->meta->make_immutable;

1;

__END__
