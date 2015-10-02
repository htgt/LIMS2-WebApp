package LIMS2::WebApp::Controller::API::SequencingProject;
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
    
    LIMS2::Model::Util::SequencingProject::build_seq_data($self, $c, $seq_id);

    return;
}
1;
