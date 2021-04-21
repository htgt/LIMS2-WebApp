package LIMS2::WebApp::Controller::API::MiseqSequencing;

use Moose;
use namespace::autoclean;
use LIMS2::Model::Util::CrispressoSubmission qw/get_parents_to_miseqs_map get_well_map/;
use JSON;
use Try::Tiny;
use List::Util qw/min max/;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub crispresso_submission :Path( '/api/crispresso_submission' ) :Args(0) :ActionClass('REST') {
}

sub crispresso_submission_GET {
    my ( $self, $c ) = @_;

    my $plate_name = lc $c->request->param('plate');
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ 'LOWER(me.name)' => $plate_name });
    my $data;
    if ($plate_rs) {
        $data = _gather_miseq_experiments($c, $plate_rs);
    }

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($data);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub _gather_miseq_experiments {
    my ($c, $plate_rs) = @_;

    my $experiments = $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({
        miseq_id => $plate_rs->miseq_plates->first->id,
    });
    my $exp_results;
    while (my $exp = $experiments->next) {
        my $parent_maps = get_parents_to_miseqs_map( $c->model('Golgi'), $exp->parent_plate_id, $plate_rs->name );
        my %well_map = get_well_map( $c->model('Golgi'), $parent_maps, 'miseq_only' );
        my @wells = map { $_->{index} } values %well_map;

        if ($exp->experiment) {
            $exp_results->{data}->{$exp->name} = _construct_experiment_details($exp, @wells);
        } else {
            push (@{ $exp_results->{errors} }, $exp->name);
        }
    }

    return $exp_results;
}

sub _construct_experiment_details {
    my ($exp, @wells) = @_;

    my $details = {
        experiment_id   => $exp->experiment_id,
        experiment      => $exp->name,
        gene            => $exp->gene,
        crispr          => $exp->experiment->crispr->seq,
        amplicon        => $exp->experiment->design->amplicon,
        parent_plate    => $exp->parent_plate->name,
        parent_plate_id => $exp->parent_plate_id,
        min_index       => min(@wells),
        max_index       => max(@wells),
        strand          => '+',
    };

    my $hdr = $exp->experiment->design->hdr_amplicon;
    $details->{hdr} = $hdr || '';

    return $details;
}

1;
