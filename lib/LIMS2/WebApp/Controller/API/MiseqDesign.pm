package LIMS2::WebApp::Controller::API::MiseqDesign;
use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use LIMS2::Model::Util::CreateMiseqDesign qw( generate_miseq_design default_nulls );
use JSON;
use Try::Tiny;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub redo_miseq_design :Path( '/api/redo_miseq_design' ) :Args(0) :ActionClass('REST') {
}

sub redo_miseq_design_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $jsonified_reqs = $c->request->param('requirements');
    my $reqs = from_json $jsonified_reqs;
    my $crispr = $reqs->{crispr};

    my $response->{lims} = $crispr;
    try {
        my $results = generate_miseq_design($c, $reqs, $crispr);
        my $design = $results->{design};

        if ($results->{error}) {
            $response->{status} = $results->{error};
            return $self->status_ok(
                $c,
                entity => "Bad Request: $response->{status}",
            );
        } else {
            my @hgncs = grep { $_ =~ /^HGNC*/ } $results->{design}->gene_ids;
            $response = {
                status  => 'Success',
                gene    => join(', ', @hgncs),
                design  => $results->{design}->id,
            };
        }
    } catch {
        return $self->status_bad_request(
            $c,
            message => "Bad Request: Can not create design",
        );
    };

    my $json = JSON->new->allow_nonref;
    my $jsonified_response = $json->encode($response);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $jsonified_response );

    return;
}

sub redo_miseq_design_GET {
    my ( $self, $c ) = @_;

    my $body = $c->model('Golgi')->schema->resultset('Design')->find ({ id => $c->request->param('id') })->as_hash;

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub miseq_primer_preset :Path( '/api/miseq_primer_preset' ) :Args(0) :ActionClass('REST') {
}

sub miseq_primer_preset_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $jsonified_criteria = $c->request->param('criteria');
    my $hashed_criteria = from_json $jsonified_criteria;
    $hashed_criteria = default_nulls($c, $hashed_criteria, { name => 'Default' });
    $hashed_criteria->{created_by} = $c->user->id;
    my $preset = $c->model('Golgi')->create_primer_preset($hashed_criteria);

    my $json = JSON->new->allow_nonref;
    my $json_preset = $json->encode($preset->as_hash);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $json_preset );

    return;
}

sub miseq_primer_preset_GET {
    my ( $self, $c ) = @_;

    my $name = $c->request->param('name');

    my $preset = $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->find({ name => $name })->as_hash;

    return $self->status_ok( $c, entity => $preset );
}

sub miseq_preset_names :Path( '/api/miseq_preset_names' ) :Args(0) :ActionClass('REST') {
}

sub miseq_preset_names_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my @results;
    try {
        @results = map { $_->name } $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->all;
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok($c, entity => \@results);
}

sub edit_miseq_primer_preset :Path( '/api/edit_miseq_primer_preset' ) :Args(0) :ActionClass('REST') {
}

sub edit_miseq_primer_preset_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $jsonified_criteria = $c->request->param('criteria');
    my $hashed_criteria = from_json $jsonified_criteria;
    $hashed_criteria = default_nulls($c, $hashed_criteria, { id => $hashed_criteria->{id} });
    $hashed_criteria->{created_by} = $c->user->id;
    my $preset = $c->model('Golgi')->edit_primer_preset($hashed_criteria);

    my $json = JSON->new->allow_nonref;
    my $json_preset = $json->encode($preset->as_hash);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $json_preset );

    return;
}

sub miseq_preset_names :Path( '/api/miseq_preset_names' ) :Args(0) :ActionClass('REST') {
}

sub miseq_preset_names_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my @results;
    try {
        @results = map { $_->name } $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->all;
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok($c, entity => \@results);
}

sub miseq_hdr_template :Path( '/api/miseq_hdr_template' ) :Args(0) :ActionClass('REST') {
}

sub miseq_hdr_template_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    #my $json_reqs = $c->request->param('requirements');
    my $id = $c->request->param('id');
    #my $reqs = from_json $json_reqs;

    #my $design_rs = $c->model('Golgi')->schema->resultset('Design')->find({ id => $reqs->{id} });
    my $design_rs = $c->model('Golgi')->schema->resultset('Design')->find({ id => $id });
    unless ($design_rs) {
        #err
    }        
    my $hdr = $design_rs->hdr_template;
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $hdr );
}

sub miseq_hdr_template_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');
}

__PACKAGE__->meta->make_immutable;

1;
