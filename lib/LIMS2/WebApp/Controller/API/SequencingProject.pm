package LIMS2::WebApp::Controller::API::SequencingProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::SequencingProject::VERSION = '0.344';
}
## use critic

use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use LIMS2::Model::Util::SequencingProject qw( build_seq_data );

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub seq_project : Path( '/api/seq_project' ) : Args(0) : ActionClass( 'REST' ) {
}

sub seq_project_GET{
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $seq_id = $c->request->param( 'seq_id' );
    my $seq_primer = $c->request->param( 'primer' );
    my $sub_number = $c->request->param( 'sub' );

    my $file = LIMS2::Model::Util::SequencingProject::build_seq_data($self, $c, $seq_id, $seq_primer, $sub_number);
    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . $file->{name}
    );
    $c->response->body( $file->{body});

    return;
}
1;
