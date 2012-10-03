package LIMS2::QC::ListLatestRuns;

use Moose;
use YAML::Any;
use List::Util qw( min );
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

has limit => (
    is => 'ro',
    isa => 'Int',
    default => 50
);

has config => (
    is => 'ro',
    isa => 'HTGT::QC::Config',
    required => 1
);

sub get_latest_run_data{
    my ( $self ) = shift;

    my @child_dirs;
    my @children = $self->config->basedir->children;
    for my $child( @children ){
        push @child_dirs, $child if $child->is_dir;
    }
    my @runs = reverse sort { $a->{ctime} <=> $b->{ctime} }
        map { { run_id => $_->dir_list(-1), ctime => $_->file("params.yaml")->stat->ctime } }
            @child_dirs;

    my $max_index = min( scalar @runs, $self->limit ) - 1;

    my @run_data;
    for my $run ( @runs[0..$max_index] ){
        my $params_file = $self->config->basedir->subdir( $run->{run_id} )->stringify
            . '/params.yaml';
        unless ( -e $params_file ){
            push @run_data, (
                {
                    qc_run_id    => $run->{run_id}
                }
            );
            next;
        }

        my $params = YAML::Any::LoadFile( $params_file );
        next unless $params->{sequencing_projects};
        my ( $last_stage, $last_stage_time ) = $self->get_last_stage_details( $run->{run_id} );

        push @run_data, (
            {
                qc_run_id       => $run->{run_id},
                created         => scalar localtime($run->{ctime}),
                profile         => $params->{profile},
                seq_projects    => join('; ', @{$params->{sequencing_projects}}),
                template_plate  => $params->{template_plate},
                last_stage      => $last_stage,
                last_stage_time => $last_stage_time
            }
        );
    }

    return \@run_data;
}

sub get_last_stage_details{
    my ( $self, $qc_run_id ) = @_;

    my @outfiles = $self->config->basedir->subdir( $qc_run_id )->subdir('output')->children;

    my @time_sorted_outfiles = reverse sort { $a->{ctime} <=> $b->{ctime} } @outfiles;

    my ($last_stage) = $time_sorted_outfiles[0]->basename =~ /^(.*)\.out$/;
    my $last_stage_ctime = $time_sorted_outfiles[0]->stat->ctime;
    my $last_stage_time = scalar localtime $last_stage_ctime;

    return ( $last_stage, $last_stage_time );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
