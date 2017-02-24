package LIMS2::WebApp::Controller::User::Experiments;
use Moose;
use Hash::MoreUtils qw( slice_def slice_exists);
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw( uniq );

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::Experiments - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub view_experiment :Path('/user/view_experiment'){
    my ( $self, $c) = @_;

    $c->assert_user_roles('read');
    my $exp_id = $c->req->param('experiment_id');
    my $exp = $c->model( 'Golgi' )->retrieve_experiment( { id => $exp_id } );
    my $gene_info =  try{ $c->model('Golgi')->find_gene( {
        search_term => $exp->gene_id,
        species => $exp->species_id,
    } ) };

    my $exp_hash = $exp->as_hash_with_detail;

    my $genotyping_param = {design_id => $exp_hash->{design_id}};
    my $genotyping_query = $c->model( 'Golgi' )->retrieve_genotyping($genotyping_param);

    $c->stash(
        experiment_id => $exp_id,
        experiment => $exp_hash,
        gene_symbol => $gene_info->{'gene_symbol'},
        genotyping => $genotyping_query,
    );

    return;
}

sub restore_experiment :Path('/user/restore_experiment'){
    my ($self, $c) = @_;

    $c->assert_user_roles('edit');
    my $exp_id = $c->req->param('experiment_id');
    my $exp = $c->model( 'Golgi' )->retrieve_experiment( { id => $exp_id } );
    my $deleted = $exp->deleted;

    if($deleted){
        $exp->update({deleted => 0});
        $c->flash->{success_msg} = "Experiment $exp_id has been restored";
    }
    $c->res->redirect( $c->uri_for('/user/view_experiment', { experiment_id => $exp_id}) );
    return;
}

__PACKAGE__->meta->make_immutable;
1;
