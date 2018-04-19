package LIMS2::t::Model::Util::Trivial::ExperimentManager;
use strict;
use warnings;
use Test::Most;

sub expect {
    my ($self, %expected) = @_;
    @{$self->{expected}}{keys %expected} = values %expected;
}

sub add {
    my ($self, $expected_trivial, $data) = @_;
    ${$data}{gene_id} = $self->{gene};
    my $new = $self->{rs}->create($data);
    ${$self->{expected}}{$new->id} = $expected_trivial;
    return $new->id;
}

sub test {
    my $self = shift;
    my $num = $self->{rs}->count( { gene_id => $self->{gene} } );
    my %expected = %{$self->{expected}};
    is ( $num, scalar(keys %expected) );

    while (my ($id, $trivial) = each (%expected)){
        my $experiment = $self->{rs}->single({ id => $id });
        is($experiment->trivial_name, $trivial);
    }
    return;
}

sub new {
    my ($class, $model, $gene) = @_;
    return bless { 
        rs => $model->schema->resultset('Experiment'),
        gene => $gene
    }, $class;
}

1;
