package LIMS2::WebApp::Controller::API::MiseqSequencing;
use Moose;
use namespace::autoclean;
use JSON;
use Try::Tiny;
use LIMS2::Model::Util::CrispressoSubmission qw/get_eps_for_plate/;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub crispresso_submission :Path( '/api/crispresso_submission' ) :Args(0) :ActionClass('REST') {
}

sub crispresso_submission_GET {
    my ( $self, $c ) = @_;
$DB::single=1;
    my $plate_name = lc $c->request->param('plate');
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ 'LOWER(me.name)' => $plate_name });
    my $eps;
    if ($plate_rs) {
        my $plate_id = $plate_rs->id;
        $eps = get_eps_for_plate($c->model('Golgi'), $plate_id);
    }

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($eps);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

1;