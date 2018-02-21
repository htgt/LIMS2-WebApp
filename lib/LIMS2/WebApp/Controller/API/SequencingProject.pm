package LIMS2::WebApp::Controller::API::SequencingProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::SequencingProject::VERSION = '0.488';
}
## use critic

use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use LIMS2::Model::Util::SequencingProject qw/build_seq_data/;
use LIMS2::WebApp::Controller::User::ExternalProject qw/update_status/;
use JSON;


BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub seq_project : Path( '/api/seq_project' ) : Args(0) : ActionClass( 'REST' ) {
}

sub seq_project_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $seq_id = $c->request->param( 'seq_id' );
    my $seq_primer = $c->request->param( 'primer' );
    my $sub_number = $c->request->param( 'sub' );
    my $mix        = $c->request->param( 'mix' );

    my $file = LIMS2::Model::Util::SequencingProject::build_seq_data($self, $c, $seq_id, $seq_primer, $sub_number, $mix);
    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $file->{name}
    );
    $c->response->body( $file->{body});

    return;
}

sub pair_project : Path( '/api/pair_project' ) : Args(0) : ActionClass( 'REST' ) {
}

sub pair_project_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');

    my $seq_id = $c->request->param( 'seq_id' );
    my $sub_number = $c->request->param( 'sub' );
    my $primers = $c->request->param( 'primers' );
    my @primers = split(/,/,$primers);

    my $file = LIMS2::Model::Util::SequencingProject::pair_sheet($self, $c, $seq_id, $sub_number, @primers);

    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $file->{name}
    );
    $c->response->body( $file->{body} );

    return;
}

sub custom_sheet : Path( '/api/custom_sheet' ) : Args(0) : ActionClass( 'REST' ) {
}

sub custom_sheet_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');

    my $sheet = $c->request->param( 'data' );
    my $name = $c->request->param( 'name' );
    my $sub = $c->request->param( 'sub' );
    my $mix = $c->request->param( 'mix' );
    my $primers = $c->request->param( 'primers' );
    my @primers = split(/,/,$primers);
    $sheet = from_json($sheet);

    my $file = LIMS2::Model::Util::SequencingProject::custom_sheet($sheet, $name, $sub, $mix, @primers);

    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $file->{name}
    );
    $c->response->body( $file->{body} );

    return;
}

sub status : Path( '/api/set_status' ) : Args(0) : ActionClass( 'REST' ) {
}

sub status_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');

    my $id = $c->request->param( 'seq_id' );
    my $abandoned = $c->request->param( 'abandoned' );

    LIMS2::WebApp::Controller::User::ExternalProject::update_status($c, $id, $abandoned);

    return;
}

1;
