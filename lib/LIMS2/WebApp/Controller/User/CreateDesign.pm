package LIMS2::WebApp::Controller::User::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CreateDesign::VERSION = '0.140';
}
## use critic


use Moose;
use namespace::autoclean;
use Data::UUID;
use Path::Class;
use Const::Fast;
use TryCatch;

use IPC::Run 'run';
use LIMS2::Util::FarmJobRunner;
use LIMS2::Exception::System;
use LIMS2::Model::Util::CreateDesign qw( exons_for_gene get_ensembl_gene );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );

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

    my $species = $c->session->{selected_species};
    my $default_assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species } )->assembly_id;

    $c->log->debug("Pick exon targets for gene $gene_name");
    try {
        my ( $gene_data, $exon_data )= exons_for_gene(
            $c->model('Golgi'),
            $c->request->param('gene'),
            $c->request->param('show_exons'),
            $species,
        );

        $c->stash(
            exons    => $exon_data,
            gene     => $gene_data,
            assembly => $default_assembly,
            species  => $species,
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
        # parse and validate params
        my $params = $self->parse_and_validate_gibson_params( $c );

        # create design attempt record
        my $design_attempt = $c->model('Golgi')->create_design_attempt(
            {
                gene_id    => $params->{gene_id},
                status     => 'pending',
                created_by => $c->user->name,
                species    => $c->session->{selected_species},
            }
        );
        $params->{da_id} = $design_attempt->id;

        $self->find_or_create_design_target( $c, $params );

        try {
            my $cmd = $self->generate_gibson_design_cmd( $params );
            $c->log->debug('Design create command: ' . join(' ', @{ $cmd } ) );

            $self->run_design_create_cmd( $c, $cmd, $params );
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
            exon_id => $exon_id,
            gene_id => $gene_id,
            ensembl_gene_id => $ensembl_gene_id,
        );
    }
    return;
}

#TODO maybe move these methods to a seperate util module, this controller is getting fat sp12 Fri 13 Dec 2013 08:33:44 GMT
sub run_design_create_cmd {
    my ( $self, $c, $cmd, $params ) = @_;

    my $runner = LIMS2::Util::FarmJobRunner->new(
        default_memory     => 2500,
        default_processors => 2,
    );

    my $job_id = $runner->submit(
        out_file => $params->{ output_dir }->file( "design_creation.out" ),
        err_file => $params->{ output_dir }->file( "design_creation.err" ),
        cmd      => $cmd,
    );

    $c->log->info( "Successfully submitted gibson design create job $job_id with run id $params->{uuid}" );

    return;
}

sub pspec_create_gibson_design {
    return {
        gene_id         => { validate => 'non_empty_string' },
        exon_id         => { validate => 'ensembl_exon_id' },
        ensembl_gene_id => { validate => 'ensembl_gene_id' },
        # fields from the diagram
        '5F_length'    => { validate => 'integer' },
        '5F_offset'    => { validate => 'integer' },
        '5R_EF_length' => { validate => 'integer' },
        '5R_EF_offset' => { validate => 'integer' },
        'ER_3F_length' => { validate => 'integer' },
        'ER_3F_offset' => { validate => 'integer' },
        '3R_length'    => { validate => 'integer' },
        '3R_offset'    => { validate => 'integer' },
        # other options
        exon_check_flank_length => { validate => 'integer', optional => 1 },
        repeat_mask_classes     => { validate => 'repeat_mask_class', optional => 1 },
        alt_designs             => { validate => 'boolean', optional => 1 },
        #submit
        create_design => { optional => 0 }
    };
}

sub parse_and_validate_gibson_params {
    my ( $self, $c ) = @_;

    my $validated_params = $c->model('Golgi')->check_params(
        $c->request->params, $self->pspec_create_gibson_design );
    $validated_params->{user} = $c->user->name;

    my $species = $c->session->{selected_species};
    my $default_assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species } )->assembly_id;

    my $uuid = Data::UUID->new->create_str;
    $validated_params->{uuid}        = $uuid;
    $validated_params->{output_dir}  = $DEFAULT_DESIGNS_DIR->subdir( $uuid );
    $validated_params->{species}     = $species;
    $validated_params->{build_id}    = $DEFAULT_SPECIES_BUILD{ lc($species) };
    $validated_params->{assembly_id} = $default_assembly;

    #create dir
    $validated_params->{output_dir}->mkpath();

    $c->stash( {
        gene_id => $validated_params->{gene_id},
        exon_id => $validated_params->{exon_id}
    } );

    return $validated_params;
}

sub generate_gibson_design_cmd {
    my ( $self, $params ) = @_;

    my @gibson_cmd_parameters = (
        'design-create',
        'gibson-design',
        '--debug',
        #required parameters
        '--created-by',  $params->{user},
        '--target-gene', $params->{gene_id},
        '--target-exon', $params->{exon_id},
        '--species',     $params->{species},
        '--dir',         $params->{output_dir}->subdir('workdir')->stringify,
        '--da-id',       $params->{da_id},
        #user specified params
        '--region-length-5f',    $params->{'5F_length'},
        '--region-offset-5f',    $params->{'5F_offset'},
        '--region-length-5r-ef', $params->{'5R_EF_length'},
        '--region-offset-5r-ef', $params->{'5R_EF_offset'},
        '--region-length-er-3f', $params->{'ER_3F_length'},
        '--region-offset-er-3f', $params->{'ER_3F_offset'},
        '--region-length-3r',    $params->{'3R_length'},
        '--region-offset-3r',    $params->{'3R_offset'},
        '--persist',
    );

    if ( $params->{repeat_mask_classes} ) {
        for my $class ( @{ $params->{repeat_mask_classes} } ){
            push @gibson_cmd_parameters, '--repeat-mask-class ' . $class;
        }
    }

    if ( $params->{alt_designs} ) {
        push @gibson_cmd_parameters, '--alt-designs';
    }

    if ( $params->{exon_check_flank_length} ) {
        push @gibson_cmd_parameters,
            '--exon-check-flank-length ' . $params->{exon_check_flank_length};
    }

    return \@gibson_cmd_parameters;
}

sub find_or_create_design_target {
    my ( $self, $c, $params ) = @_;

    my $existing_design_target = $c->model('Golgi')->schema->resultset('DesignTarget')->find(
        {
            species_id      => $params->{species},
            ensembl_exon_id => $params->{exon_id},
            build_id        => $params->{build_id},
        }
    );

    if ( $existing_design_target ) {
        $c->log->debug( 'Design target ' . $existing_design_target->id
                . ' already exists for exon: ' . $params->{exon_id} );
        return;
    }

    my $gene = get_ensembl_gene( $c->model('Golgi'), $params->{ensembl_gene_id}, $params->{species} );
    LIMS2::Exception->throw( "Unable to find ensembl gene: " . $params->{ensembl_gene_id} )
        unless $gene;
    my $canonical_transcript = $gene->canonical_transcript;

    my $exon;
    try {
        $exon = $c->model('Golgi')->ensembl_exon_adaptor( $params->{species} )
            ->fetch_by_stable_id( $params->{exon_id} );
    }
    LIMS2::Exception->throw( "Unable to find ensembl exon for: " . $params->{exon_id} )
        unless $exon;

    my %design_target_params = (
        species              => $params->{species},
        gene_id              => $params->{gene_id},
        marker_symbol        => $gene->external_name,
        ensembl_gene_id      => $gene->stable_id,
        ensembl_exon_id      => $params->{exon_id},
        exon_size            => $exon->length,
        canonical_transcript => $canonical_transcript->stable_id,
        assembly             => $params->{assembly_id},
        build                => $params->{build_id},
        chr_name             => $exon->seq_region_name,
        chr_start            => $exon->seq_region_start,
        chr_end              => $exon->seq_region_end,
        chr_strand           => $exon->seq_region_strand,
        automatically_picked => 0,
        comment              => 'picked via gibson design creation interface, by user: ' . $params->{user},

    );
    my $exon_rank = get_exon_rank( $exon, $canonical_transcript );
    $design_target_params{exon_rank} = $exon_rank if $exon_rank;
    my $design_target = $c->model('Golgi')->create_design_target( \%design_target_params );

    return;
}

=head2 get_exon_rank

Get rank of exon on canonical transcript

=cut
sub get_exon_rank {
    my ( $exon, $canonical_transcript ) = @_;

    my $rank = 1;
    for my $current_exon ( @{ $canonical_transcript->get_all_Exons } ) {
        return $rank if $current_exon->stable_id eq $exon->stable_id;
        $rank++;
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
