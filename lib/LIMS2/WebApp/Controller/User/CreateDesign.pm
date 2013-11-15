package LIMS2::WebApp::Controller::User::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CreateDesign::VERSION = '0.126';
}
## use critic


use Moose;
use namespace::autoclean;
use Data::UUID;
use Path::Class;
use Const::Fast;
use Try::Tiny;

use LIMS2::Util::FarmJobRunner;

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
        };
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

__PACKAGE__->meta->make_immutable;

1;