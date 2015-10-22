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

    $c->stash(
        experiment_id => $exp_id,
        experiment => $exp->as_hash_with_detail,
        gene_symbol => $gene_info->{'gene_symbol'},
    );

    return;
}
__PACKAGE__->meta->make_immutable;
1;
