package LIMS2::WebApp::Controller::API::QC;
use Moose;
use namespace::autoclean;

BEGIN { extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_template : Path( '/api/qc_template' ) : Args(0) : ActionClass( 'REST' ) {
}

=head2 GET /api/qc_template

Retrieve qc template(s). If no parameters are given, returns a list of available templates.

=head3 Parameters

=over 4

=item C<id>

The template id

=item C<name>

The template name

Note: this is ignored if C<id> is specified.

=item latest

Boolean. By default, the latest version of a template with the
specified name is returned. If C<latest=0> is specified, all versions of
the template are returned.

Note: this is ignored if C<id> is specified.

=item C<created_before>

Timestamp - used to retrieve an earlier version of a template.

Note: this is ignored if C<id> is specified.

=back

=cut

sub qc_template_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $templates = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_qc_templates( $c->request->params );
        }
    );    

    my $entity;
    
    if ( @{$templates} > 1 ) {
        $entity = [
            map +{
                id   => $_->{id},
                name => $_->{name},
                url  => $c->uri_for( '/api/qc/template', { id => $_->{id} } )
            }, @{$templates}
        ];        
    }
    else {
        $entity = $templates;
    }
    
    return $self->status_ok( $c, entity => $entity );
}

=head2 POST /api/qc_template

If a template exists with the specified name and layout, return the
existing template. Otherwise, creates and returns a new template.

=cut

sub qc_template_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $qc_template = $c->model('Golgi')->txn_do(
        sub {
            shift->find_or_create_qc_template( $c->request->data );
        }
    );    

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_template', { id => $qc_template->id } ),
        entity   => $qc_template
    );    
}

# sub qc_runs : Path( '/api/qc_runs' ) : Args(0) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_runs

# Retrieve list of QC runs

# =cut

# sub qc_runs_GET {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_runs = $c->model('Golgi')->retrieve_list( QcRun => {}, { columns => [qw( id )] } );

#     return $self->status_ok(
#         $c,
#         entity => {
#             map { $_->id => $c->uri_for( '/api/qc_run/' . $_->id )->as_string } @{$qc_runs}
#         },
#     );
# }

# =head2 POST /api/qc_runs

# Create a QcRun

# =cut

# sub qc_runs_POST {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('edit');

#     my $qc_run = $c->model('Golgi')->txn_do(
#         sub {
#             shift->create_qc_run( $c->request->data );
#         }
#     );

#     return $self->status_created(
#         $c,
#         location => $c->uri_for( '/api/qc_run/', $qc_run->id ),
#         entity   => $qc_run,
#     );
# }

# sub qc_run : Path( '/api/qc_run' ) : Args(0) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_run?id=XXX

# Retrieve a specific qc_run, by qc_run_id

# =cut

# sub qc_run_GET {
#     my ( $self, $c, $qc_run_id ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_run = $c->model('Golgi')->retrieve_qc_run( $c->request->params );

#     return $self->status_ok( $c, entity => $qc_run, );
# }

# sub qc_seq_reads : Path( '/api/qc_seq_reads' ) : Args(0) : ActionClass('REST') {
# }

# =head2 GET /api/qc_seq_reads

# Retrieve list of QcSeqReads

# =cut

# sub qc_seq_reads_GET {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_seq_reads = $c->model('Golgi')->retrieve_list( QcSeqRead => {}, { columns => [qw( id )] } );

#     return $self->status_ok(
#         $c,
#         entity => {
#             map { $_->id => $c->uri_for( '/api/qc_seq_read/' . $_->id )->as_string } @{$qc_seq_reads}
#         }
#     );
# }

# =head2 POST /api/qc_seq_reads

# Create a QcSeqRead

# =cut

# sub qc_seq_reads_POST {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('edit');

#     my $qc_seq_read = $c->model('Golgi')->txn_do(
#         sub {
#             shift->create_qc_seq_read( $c->request->data );
#         }
#     );

#     return $self->status_created(
#         $c,
#         location => $c->uri_for( '/api/qc_seq_read/', $qc_seq_read->id ),
#         entity   => $qc_seq_read,
#     );
# }

# sub qc_seq_read : Path( '/api/qc_seq_read' ) : Args(1) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_seq_read

# Retrieve a specific QcSeqRead, by qc_seq_read_id

# =cut

# sub qc_seq_read_GET {
#     my ( $self, $c, $qc_seq_read_id ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_seq_read = $c->model('Golgi')->retrieve( QcSeqRead => { id => $qc_seq_read_id } );

#     return $self->status_ok( $c, entity => $qc_seq_read, );
# }

# sub qc_sequencing_projects : Path( '/api/qc_sequencing_projects' ) : Args(0) : ActionClass('REST') {
# }

# =head2 GET /api/qc_sequencing_projects

# Retrieve list of QcSeqReads

# =cut

# sub qc_sequencing_projects_GET {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_sequencing_projects
#         = $c->model('Golgi')->retrieve_list( QcSequencingProject => {}, { columns => [qw( name )] } );

#     return $self->status_ok(
#         $c,
#         entity => {
#             map { $_->name => $c->uri_for( '/api/qc_sequencing_project/' . $_->name )->as_string }
#                 @{$qc_sequencing_projects}
#         },
#     );
# }

# =head2 POST /api/qc_sequencing_projects

# Create a QcSequencingProject

# =cut

# sub qc_sequencing_projects_POST {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('edit');

#     my $qc_sequencing_project = $c->model('Golgi')->txn_do(
#         sub {
#             shift->create_qc_sequencing_project( $c->request->data );
#         }
#     );

#     return $self->status_created(
#         $c,
#         location => $c->uri_for( '/api/qc_sequencing_project/', $qc_sequencing_project->name ),
#         entity   => $qc_sequencing_project,
#     );
# }

# sub qc_sequencing_project : Path( '/api/qc_sequencing_project' ) : Args(1) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_sequencing_project

# Retrieve a specific QcSequencingProject, by qc_sequencing_project

# =cut

# sub qc_sequencing_project_GET {
#     my ( $self, $c, $qc_sequencing_project_name ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_sequencing_project
#         = $c->model('Golgi')->retrieve( QcSequencingProject => { name => $qc_sequencing_project_name } );

#     return $self->status_ok( $c, entity => $qc_sequencing_project );
# }

# sub qc_templates : Path( '/api/qc_templates' ) : Args(0) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_templates

# Retrieve list of QcTemplate plates

# =cut

# sub qc_templates_GET {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_templates = $c->model('Golgi')->retrieve_list( QcTemplate => {}, { columns => [qw( id name )] } );

#     return $self->status_ok(
#         $c,
#         entity => {
#             map { $_->name => $c->uri_for( '/api/qc_template/' . $_->id )->as_string } @{$qc_templates}
#         }
#     );
# }

# =head2 POST /api/qc_templates

# Create a QcTemplate plate along with its wells

# =cut

# sub qc_templates_POST {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('edit');

#     my $qc_template = $c->model('Golgi')->txn_do(
#         sub {
#             shift->find_or_create_qc_template( $c->request->data );
#         }
#     );

#     return $self->status_created(
#         $c,
#         location => $c->uri_for( '/api/qc_template/', $qc_template->id ),
#         entity   => $qc_template
#     );
# }


# sub qc_test_results : Path( '/api/qc_test_results' ) : Args(0) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_test_results

# Retrieve list of QcTestResults

# =cut

# sub qc_test_results_GET {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_test_result = $c->model('Golgi')->retrieve_list( QcTestResult => {}, { columns => [qw( id )] } );

#     return $self->status_ok(
#         $c,
#         entity => {
#             map { $_->id => $c->uri_for( '/api/qc_test_result/' . $_->id )->as_string } @{$qc_test_result}
#         }
#     );
# }

# =head2 POST /api/qc_test_results

# Create a QcTestResult

# =cut

# sub qc_test_results_POST {
#     my ( $self, $c ) = @_;

#     $c->assert_user_roles('edit');

#     my $qc_test_result = $c->model('Golgi')->txn_do(
#         sub {
#             shift->create_qc_test_result( $c->request->data );
#         }
#     );

#     return $self->status_created(
#         $c,
#         location => $c->uri_for( '/api/qc_test_result/', $qc_test_result->id ),
#         entity   => $qc_test_result,
#     );
# }

# sub qc_test_result : Path( '/api/qc_test_result' ) : Args(1) : ActionClass( 'REST' ) {
# }

# =head2 GET /api/qc_test_result/$qc_test_result_id

# Retrieve a specific QcTestResult, by qc_test_result_id

# =cut

# sub qc_test_result_GET {
#     my ( $self, $c, $qc_test_result_id ) = @_;

#     $c->assert_user_roles('read');

#     my $qc_test_result = $c->model('Golgi')->retrieve( QcTestResult => { id => $qc_test_result_id } );

#     return $self->status_ok( $c, entity => $qc_test_result, );
# }

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
