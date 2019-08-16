package LIMS2::WebApp::Controller::API::MiseqSequencing;

use Moose;
use namespace::autoclean;
use JSON;
use Try::Tiny;
use LIMS2::Model::Util::CrispressoSubmission qw( get_eps_to_miseqs_map get_well_map );
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
$DB::single=1;
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
        my $parent_maps = LIMS2::Model::Util::CrispressoSubmission::get_eps_to_miseqs_map( $c->model('Golgi'), $exp->parent_plate_id );
        my %well_map = LIMS2::Model::Util::CrispressoSubmission::get_well_map( $c->model('Golgi'), $parent_maps );
        my @wells = map { $_->{index} } values %well_map;
$DB::single=1;
        $exp_results->{$exp->id} = {
            exp_id          => $exp->experiment_id,
            name            => $exp->name,
            gene            => $exp->gene,
            crispr          => $exp->experiment->crispr->seq,
            amplicon        => $exp->experiment->design->amplicon,
            parent_plate    => $exp->parent_plate->name,
            parent_id       => $exp->parent_plate_id,
            min_index       => min(@wells),
            max_index       => max(@wells),
        };
        my $hdr = $exp->experiment->design->hdr_template;
        if ($hdr) {
            $exp_results->{$exp->id}->{hdr} = $hdr;
        }
    }

    return $exp_results;
}

1;