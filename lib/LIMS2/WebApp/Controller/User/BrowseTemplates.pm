package LIMS2::WebApp::Controller::User::BrowseTemplates;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BrowseTemplates::VERSION = '0.312';
}
## use critic

use Moose;
use LIMS2::WebApp::Pageset;
use Try::Tiny;
use LIMS2::Model::Util::EngSeqParams qw(generate_genbank_for_qc_well);
use LIMS2::Model::Util::QCTemplates qw(qc_template_display_data);
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::BrowseTemplates - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/user/browse_templates' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    if ( $params->{show_all} ) {
        delete @{$params}{ qw( show_all template_name ) };
    }

    my ( $templates, $pager ) = $c->model('Golgi')->list_templates(
        {
            template_name => $params->{template_name},
            species       => $params->{species} || $c->session->{selected_species},
            page          => $params->{page},
            pagesize      => $params->{pagesize}
        }
    );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->uri_for( '/user/browse_templates', $params )
        }
    );

    $c->stash(
        template_name       => $params->{template_name},
        templates           => $templates,
        pageset             => $pageset
    );

    return;
}

sub view :Path( '/user/view_template' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    # Download genbank for well if requested
    if (my $well_id = $params->{genbank_well_id}){
    	$self->_download_genbank_for_qc_well($c, $well_id);
    	return;
    }

    my $template = $c->model('Golgi')->retrieve_qc_template( $c->request->params );
    my @run_ids = map{ $_->id } $template->qc_runs->all;

    my ( $well_data, $crispr )
        = qc_template_display_data( $c->model('Golgi'), $template, $c->session->{selected_species} );

    $c->stash(
        qc_template => $template,
        wells       => $well_data,
        qc_run_ids  => \@run_ids,
        crispr      => $crispr,
    );

    return;
}

sub delete_template :Path( '/user/delete_template') :Args(0) {
	my ($self, $c) = @_;

    my $params = $c->request->params;

    unless ( $params->{id} ) {
        $c->flash->{error_msg} = 'No template_id specified';
        $c->res->redirect( $c->uri_for('/user/browse_templates') );
        return;
    }

    $c->assert_user_roles( 'edit' );

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->delete_qc_template( { id => $params->{id}, delete_runs => 1 } );
                $c->flash->{success_msg} = 'Deleted template ' . $params->{name};
                $c->res->redirect( $c->uri_for('/user/browse_templates') );
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting template: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_template', { id => $params->{id} }) );
            };
        }
    );
    return;
}

sub _download_genbank_for_qc_well {
	my ($self, $c, $well_id) = @_;

    $c->assert_user_roles( 'read' );

    try{
        my $qc_well = $c->model('Golgi')->retrieve_qc_template_well({ id => $well_id});

        my $fh_tmp = File::Temp->new() or die "Could not open temp file - $!";

        generate_genbank_for_qc_well($qc_well,$fh_tmp);

        # reopen filehandle as Seq::IO writer closes it
	    open (my $fh, "<", $fh_tmp->filename)
	        or die ("Could not open temp file ".$fh_tmp." for reading - $!");

	    my $filename = $qc_well->qc_template->name."_".$qc_well->name.".gbk";

        $c->res->content_type('text/plain');
        $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
        $c->res->body( do{ local $/ = undef; <$fh> } );
        close $fh;
    }
    catch{
    	$c->stash->{error_msg} = 'Error generating genbank file for qc template well: '.$_;
    };

    return;
}

__PACKAGE__->meta->make_immutable;

1;
