package LIMS2::WebApp::Controller::User;
use Moose;
use LIMS2::Model::Util::ReportForSponsors;
use Text::CSV;
use Try::Tiny;
use namespace::autoclean;
use LIMS2::Util::Errbit;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';
    if($protocol eq 'HTTPS'){
        my $base = $c->req->base;
        $base =~ s/^http:/https:/;
        $c->req->base(URI->new($base));
        $c->req->secure(1);
    }

    $c->require_ssl;

    return;
}

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( ! $c->user_exists ) {
        if($c->req->path eq ""){
            # Send anonymous users to the public sponsor report instead of root
            $c->log->debug("redirecting anonymous user from / to public reports");
            $c->go( 'Controller::PublicReports', 'sponsor_report' );
        }
        else{
            $c->stash->{error_msg} = 'You must login to access '.$c->request->uri ;
            $c->stash->{goto_on_success} = $c->request->uri ;
            $c->go( 'Controller::Auth', 'login' );
        }
    }

    my $prefs = $c->model('Golgi')->retrieve_user_preferences( { id => $c->user->id } );
    if ( ! $c->session->{selected_species} ) {
        $c->session->{selected_species} = $prefs->default_species_id;
    }
    if(! $c->session->{selected_pipeline}) {
     $c->session->{selected_pipeline} = $prefs->default_pipeline_id;
    }
    if ( ! $c->session->{display_type} ) {
        $c->session->{display_type} = 'default';
    }
    if ( ! $c->session->{species} ) {
        $c->session->{species} = $c->model('Golgi')->list_species;
    }
    if ( ! $c->session->{pipeline} ) {
        $c->session->{pipeline} = $c->model('Golgi')->list_pipeline;
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

        #try to log an errbit error
        try {
            my $errbit = LIMS2::Util::Errbit->new_with_config;
            $errbit->submit_errors( $c, \@errors );
        }
        catch {
            $c->log->error( @_ );
        };

        return $c->go( 'error' );
    }

    return $c->detach( 'Controller::Root', 'end' );
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    return;
}

=head2 error

=cut

sub error :Local {
    my ( $self, $c ) = @_;
    $c->stash( template => 'user/error.tt' );
    return;
}

=head2 select_pipeline

=cut

sub select_pipeline :Local {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');

    my $pipeline_id = $c->request->param('pipeline');
    my $goto = $c->stash->{goto_on_success} || $c->req->param('goto_on_success') || $c->uri_for('/');

    $c->model('Golgi')->txn_do(
        sub {
            shift->set_user_preferences(
                {
                    id              => $c->user->id,
                    default_pipeline => $pipeline_id
                }
            );
        }
    );

    $c->session->{selected_pipeline} = $pipeline_id;

    $c->flash( info_msg => "Switched to $pipeline_id" );

    return $c->response->redirect( $goto );
}





=head2 select_species

=cut

sub select_species  :Local {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $species_id = $c->request->param('species');
    my $goto = $c->stash->{goto_on_success} || $c->req->param('goto_on_success') || $c->uri_for('/');

    my $user_rs = $c->model('Golgi')->txn_do(
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
    $c->session->{selected_pipeline} = $user_rs->pipeline;
    $c->flash( info_msg => "Switched to species $species_id" );

    return $c->response->redirect( $goto );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
