package LIMS2::WebApp::Controller::User::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CreateDesign::VERSION = '0.144';
}
## use critic


use Moose;
use namespace::autoclean;
use Const::Fast;
use TryCatch;
use Path::Class;

use LIMS2::Exception::System;
use LIMS2::Model::Util::CreateDesign;

BEGIN { extends 'Catalyst::Controller' };

#use this default if the env var isnt set.
const my $DEFAULT_DESIGNS_DIR => dir( $ENV{ DEFAULT_DESIGNS_DIR } //
                                    '/lustre/scratch109/sanger/team87/lims2_designs' );
const my @DESIGN_TYPES => (
            { cmd => 'ins-del-design --design-method deletion', display_name => 'Deletion' }, #the cmd will change
            #{ cmd => 'insertion-design', display_name => 'Insertion' },
            #{ cmd => 'conditional-design', display_name => 'Conditional' },
        ); #display name is used to populate the dropdown

#oligo select will be something like:
#const my @OLIGO_SELECT_METHODS => (
#        { cmd => 'block', display_name => 'Block Specified' },
#        { cmd => 'location', display_name => 'Location Specified' }
#    );

#
# TODO: add javascript to make sure target start isnt > target end
#

sub index : Path( '/user/create_design' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    #used to populate the design type dropdown.
    $c->stash( design_types => \@DESIGN_TYPES );

    my $params = $c->request->params;

    if ( exists $c->request->params->{ create_design } ) {
        $c->model( 'Golgi' )->check_params( $params, $self->pspec_create_design );

        #we need the username and this saves passing the whole $c object.
        $params->{ user_id } = $c->user->name;

        $c->stash( {
            target_gene  => $params->{ target_gene },
            target_start => $params->{ target_start },
            target_end   => $params->{ target_end },
            chromosome   => $params->{ chromosome },
            strand       => $params->{ strand },
        } );

        my $uuid = Data::UUID->new->create_str;
        $params->{ output_dir } = $DEFAULT_DESIGNS_DIR->subdir( $uuid );

        #all the parameters are in order so bsub a design creation job
        my $runner = LIMS2::Util::FarmJobRunner->new;

        try {
            my $job_id = $runner->submit(
                out_file => $params->{ output_dir }->file( "design_creation.out" ),
                cmd      => $self->get_design_cmd( $params ),
            );

            $c->stash( success_msg => "Successfully created job $job_id with run id $uuid" );
        }
        catch {
            $c->stash( error_msg => "Error submitting Design Creation job: $_" );
            return;
        }
    }

    return;

    #ins-del-design --design-method deletion --chromosome 11 --strand 1
    #--target-start 101176328 --target-end 101176428 --target-gene LBLtest
    #--dir /nfs/users/nfs_a/ah19/new_dc_test --debug"
}

sub get_design_cmd {
    my ( $self, $params ) = @_;

    #this function should eventually process the user supplied info and determine
    #what parameters to give to design-create

    #an undef here will raise an exception.

    return [
        'design-create',
        $DESIGN_TYPES[ $params->{ design_type } ]->{ 'cmd' }, #look up selected design type cmd
        '--debug',
        '--created-by', $params->{ user_id },
        #required parameters
        '--target-gene', $params->{ target_gene },
        '--target-start', $params->{ target_start },
        '--target-end', $params->{ target_end },
        '--chromosome', $params->{ chromosome },
        '--strand', $params->{ strand },
        '--dir', $params->{ output_dir },
        #user specified lengths
        '--g5-region-length', $params->{ g5_length },
        '--u5-region-length', $params->{ u5_length },
        '--d3-region-length', $params->{ d3_length },
        '--g3-region-length', $params->{ g3_length },
        #user specified offsets
        '--g5-region-offset', $params->{ g5_offset },
        '--u5-region-offset', $params->{ u5_offset },
        '--d3-region-offset', $params->{ d3_offset },
        '--g3-region-offset', $params->{ g3_offset },
        '--persist',
    ];
}

sub pspec_create_design {
    return {
        design_type   => { validate => 'integer' },
        target_gene   => { validate => 'non_empty_string' },
        target_start  => { validate => 'integer' },
        target_end    => { validate => 'integer' },
        chromosome    => { validate => 'existing_chromosome' },
        strand        => { validate => 'strand' },
        #fields from the diagram
        g5_length     => { validate => 'integer' },
        u5_length     => { validate => 'integer' },
        d3_length     => { validate => 'integer' },
        g3_length     => { validate => 'integer' },
        u5_offset     => { validate => 'integer' },
        d3_offset     => { validate => 'integer' },
        g5_offset     => { validate => 'integer' },
        g3_offset     => { validate => 'integer' },
        create_design => { optional => 0 } #this is the submit button
    };
}

sub gibson_design_gene_pick : Path('/user/gibson_design_gene_pick') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    return;
}

sub gibson_design_exon_pick : Path( '/user/gibson_design_exon_pick' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    my $gene_name = $c->request->param('gene');
    unless ( $gene_name ) {
        $c->stash( error_msg => "Please enter a gene name" );
        return $c->go('gibson_design_gene_pick');
    }

    $c->log->debug("Pick exon targets for gene $gene_name");
    try {

        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );
        my ( $gene_data, $exon_data )= $create_design_util->exons_for_gene(
            $c->request->param('gene'),
            $c->request->param('show_exons'),
        );

        $c->stash(
            exons    => $exon_data,
            gene     => $gene_data,
            assembly => $create_design_util->assembly_id,
        );
    }
    catch( LIMS2::Exception $e ) {
        $c->stash( error_msg => "Problem finding gene: $e" );
        $c->go('gibson_design_gene_pick');
    };

    return;
}

sub create_gibson_design : Path( '/user/create_gibson_design' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    if ( exists $c->request->params->{create_design} ) {
        $c->log->info('Creating new design');

        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );

        my $design_attempt;
        try {
            $design_attempt = $create_design_util->create_gibson_design();
        }
        catch ($err) {
            $c->flash( error_msg => "Error submitting Design Creation job: $err" );
            $c->res->redirect( 'gibson_design_gene_pick' );
            return;
        }

        $c->res->redirect( $c->uri_for('/user/design_attempt', $design_attempt->id , 'pending') );
    }
    elsif ( exists $c->request->params->{exon_pick} ) {
        my $gene_id = $c->request->param('gene_id');
        my $exon_id = $c->request->param('exon_id');
        my $ensembl_gene_id = $c->request->param('ensembl_gene_id');
        $c->stash(
            exon_id         => $exon_id,
            gene_id         => $gene_id,
            ensembl_gene_id => $ensembl_gene_id,
        );
    }

    return;
}

sub design_attempts :Path( '/user/design_attempts' ) : Args(0) {
    my ( $self, $c ) = @_;

    #TODO add filtering, e.g. by user, status, gene etc

    my @design_attempts = $c->model('Golgi')->schema->resultset('DesignAttempt')->search(
        {
            species_id => $c->session->{selected_species},
        },
        {
            order_by => { '-desc' => 'created_at' },
            rows => 50,
        }
    );

    $c->stash (
        das => [ map { $_->as_hash( { json_as_hash => 1 } ) } @design_attempts ],
    );
    return;
}

sub design_attempt : PathPart('user/design_attempt') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $design_attempt_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my $design_attempt;
    try {
        $design_attempt = $c->model('Golgi')
            ->retrieve_design_attempt( { id => $design_attempt_id, species => $species_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid design attempt id" );
        return $c->go('design_attempts');
    }
    catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Design Attempt $design_attempt_id not found" );
        return $c->go('design_attempts');
    }

    $c->log->debug( "Retrived design_attempt: $design_attempt_id" );

    $c->stash(
        da      => $design_attempt,
        species => $species_id,
    );

    return;
}

sub view_design_attempt : PathPart('view') Chained('design_attempt') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        da => $c->stash->{da}->as_hash( { pretty_print_json => 1 } ),
    );
    return;
}

sub pending_design_attempt : PathPart('pending') Chained('design_attempt') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        id      => $c->stash->{da}->id,
        status  => $c->stash->{da}->status,
        gene_id => $c->stash->{da}->gene_id,
    );
    return;
}

__PACKAGE__->meta->make_immutable;

1;
