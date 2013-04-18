package LIMS2::WebApp::Controller::User;
use Moose;
#use LIMS2::Report;
use LIMS2::Model::Util::ReportForSponsors;
use Text::CSV;
use namespace::autoclean;
use Smart::Comments;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( ! $c->user_exists ) {
        $c->stash( error_msg => 'Please login to access this system' );
        $c->stash( goto_on_success => $c->request->uri );
        $c->go( 'Controller::Auth', 'login' );
    }

    if ( ! $c->session->{selected_species} ) {
        my $prefs = $c->model('Golgi')->retrieve_user_preferences( { id => $c->user->id } );
        $c->session->{selected_species} = $prefs->default_species_id;
    }

    if ( ! $c->session->{species} ) {
        $c->session->{species} = $c->model('Golgi')->list_species;
    }

    return 1;
}

=head2 end

If we are runnning in production, we don't want to scare off the users
with the Catalyst error message. But in debug mode, we want the stack
trace in its full glory. This method runs at the end of a request and,
if we have errors and are not in debug mode, redirects to the index
with a simple error message.

=cut

sub end :Private {
    my ( $self, $c ) = @_;

    my @errors = @{ $c->error };
    if ( @errors > 0 && ! $c->debug ) {
        $c->log->error( $_ ) for @errors;
        $c->clear_errors;
        $c->stash( errors => \@errors );
        return $c->go( 'error' );
    }

    return $c->detach( 'Controller::Root', 'end' );
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $species = $c->session->{selected_species};

    # Call ReportForSponsors plugin to generate report 
    my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new( { species => $species, model => $c->model( 'Golgi' ) } );
    my $report_params = $sponsor_report->generate_top_level_report_for_sponsors();

    # Fetch details from returned report parameters
    my $report_id = $report_params->{ report_id };
    my $title = $report_params->{ title };
    my $columns = $report_params->{ columns };
    my $st_rows = $report_params->{ st_rows };
    my $dt_rows = $report_params->{ dt_rows };
    #my $st_data = $report_params->{ st_data };
    #my $dt_data = $report_params->{ dt_data };
    my $data = $report_params->{ data };

    # Store report values in stash for display onscreen
    $c->stash(
        'report_id' => $report_id,
        'title'     => $title,
        'columns'   => $columns,
        'st_rows'   => $st_rows,
 #       'st_data'   => $st_data,
        'dt_rows'   => $dt_rows,
 #       'dt_data'   => $dt_data,
        'data'      => $data,
    );

    return;
}

=head2 error

=cut

sub error :Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'user/error.tt' );
    return;
}

=head2 select_species

=cut

sub select_species :Local {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $species_id = $c->request->param('species');

    $c->model('Golgi')->txn_do(
        sub {
            shift->set_user_preferences(
                {
                    id              => $c->user->id,
                    default_species => $species_id
                }
            );
        }
    );

    $c->session->{selected_species} = $species_id;

    $c->flash( info_msg => "Switched to species $species_id" );

    return $c->response->redirect( $c->uri_for('/') );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
