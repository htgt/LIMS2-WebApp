package LIMS2::WebApp::Controller::User::CreateDesign;

use Moose;
use namespace::autoclean;
use Data::UUID;
use Path::Class;
use Const::Fast;
use Try::Tiny;

use LIMS2::Util::FarmJobRunner;

BEGIN { extends 'Catalyst::Controller' };

const my $DEFAULT_DESIGNS_DIR => dir( '/', 'lustre', 'scratch109', 'sanger', 'team87', 'lims2_designs' );

#
#
# TODO ON MONDAY:
#   map the new diagram fields to actual flags in saj's program.
#   assuming the art intron bit is just a flag, also map that.
#   strand needs another option
#   do some runs and check its all working
#   run it by mark
#   see what he requires next.
#   add a link to this page
#
#

#TODO: add link to this page 
sub index : Path( '/user/create_design' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    #target start
    #target end
    #chromosome
    #strand
    #dir

    my $params = $c->request->params;

    if ( exists $c->request->params->{ create_design } ) {
        $c->model( 'Golgi' )->check_params( $params, $self->pspec_create_design );

        $c->stash( {
            target_gene  => $params->{ target_gene }, #why have i added || undef??
            target_start => $params->{ target_start },
            target_end   => $params->{ target_end },
            chromosome   => $params->{ chromosome },
            strand       => $params->{ strand },
        } );

        #allow this to be overridden with an env var or config or whatever.
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

    #ins-del-design --design-method deletion --chromosome 11 --strand 1 
    #--target-start 101176328 --target-end 101176428 --target-gene LBLtest 
    #--dir /nfs/users/nfs_a/ah19/new_dc_test --debug"

    #deal with optional stuff later - 
        #design comment
        #created by
        #all the sizes and offsets as listed in saj's diagram

    #
    #call target gene something else?
    #dropdown for chromosome?
    #
}

sub get_design_cmd {
    my ( $self, $params ) = @_;

    #this function should eventually process the user supplied info and determine
    #what parameters to give to design-create

    #an undef here will raise an exception.

    return [
        'design-create', 'ins-del-design', #this will change, naturally
        '--debug',
        '--design-method', 'deletion', #this will also change. probably all of it
        '--target-gene', $params->{ target_gene },
        '--target-start', $params->{ target_start },
        '--target-end', $params->{ target_end },
        '--chromosome', $params->{ chromosome },
        '--strand', $params->{ strand },
        '--dir', $params->{ output_dir },
        '--persist',
    ];
}

sub pspec_create_design {
    return {
        target_gene   => { validate => 'non_empty_string' },
        target_start  => { validate => 'integer' },
        target_end    => { validate => 'integer' },
        chromosome    => { validate => 'existing_chromosome' },
        strand        => { validate => 'strand' },
        create_design => { optional => 0 } #this is the submit button
    };
} 

__PACKAGE__->meta->make_immutable;

1;