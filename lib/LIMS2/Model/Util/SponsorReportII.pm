package LIMS2::Model::Util::SponsorReportII;

use strict;
use warnings;
use Moose;
use Data::Dumper;

extends qw( LIMS2::ReportGenerator );

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has sponsor_gene_count => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_gene_count {
    my $self = shift;
    my $sponsor_gene_count;

    my @project_ii_rs = $self->model->schema->resultset('Project')->search(
          { strategy_id => 'Pipeline II' },
          { distinct => 1 }
        )->all;

    my @projects_ii = map { $_->id } @project_ii_rs;

    my @project_sponsor_rs = $self->model->schema->resultset('ProjectSponsor')->search(
          { project_id => { -in => \@projects_ii }, sponsor_id => { 'not in' => ['All'] } },
          { distinct => 1 }
        )->all;

    foreach my $rec ( @project_sponsor_rs ) {
        $sponsor_gene_count->{$rec->sponsor_id}++;
    }

    return $sponsor_gene_count;
}

## rule-based subs

1;
