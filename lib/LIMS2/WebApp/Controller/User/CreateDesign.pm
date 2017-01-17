package LIMS2::WebApp::Controller::User::CreateDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CreateDesign::VERSION = '0.439';
}
## use critic


use Moose;
use namespace::autoclean;
use Const::Fast;
use TryCatch;
use Path::Class;
use Hash::MoreUtils qw( slice_def );

use LIMS2::Exception::System;
use WebAppCommon::Util::FarmJobRunner;

use LIMS2::REST::Client;
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );
use LIMS2::Model::Util::CreateDesign qw( &convert_gibson_to_fusion );
use DesignCreate::Types qw( PositiveInt Strand Chromosome Species );
use WebAppCommon::Design::DesignParameters qw( c_get_design_region_coords );
use LIMS2::Model::Util::GenomeBrowser qw(design_params_to_gff);
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' };

has chr_name => (
    is         => 'ro',
    isa        => Chromosome,
    traits     => [ 'NoGetopt' ],
    lazy_build => 1,
);

sub _build_chr_name {
    my $self = shift;

    return $self->{chr_name};
}

has chr_strand => (
    is         => 'ro',
    isa        => Strand,
    traits     => [ 'NoGetopt' ],
    lazy_build => 1,
);

sub _build_chr_strand {
    my $self = shift;

    return $self->{chr_strand};
}

has ensembl_util => (
    is         => 'ro',
    isa        => 'WebAppCommon::Util::EnsEMBL',
    traits     => [ 'NoGetopt' ],
    lazy_build => 1,
    handles    => [ qw( slice_adaptor exon_adaptor gene_adaptor ) ],
);

sub _build_ensembl_util {
    my $self = shift;
    require WebAppCommon::Util::EnsEMBL;

    my $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $self->{species} );

    # this flag should stop the database connection being lost on long jobs
    $ensembl_util->registry->set_reconnect_when_lost;

    return $ensembl_util;
}

#use this default if the env var isnt set.
const my $DEFAULT_DESIGNS_DIR => dir( $ENV{DEFAULT_DESIGNS_DIR} //
                                    '/lustre/scratch109/sanger/team87/lims2_designs' );
const my @DESIGN_TYPES => (
            { cmd => 'ins-del-design --design-method deletion', display_name => 'Deletion' }, #the cmd will change
            #{ cmd => 'insertion-design', display_name => 'Insertion' },
            #{ cmd => 'conditional-design', display_name => 'Conditional' },
        ); #display name is used to populate the dropdown

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
        my $runner = WebAppCommon::Util::FarmJobRunner->new;

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
    if ($c->req->param('gibson_id')) {
        my $id = $c->req->param('gibson_id');

        my $design = $c->model('Golgi')->schema->resultset('Design')->find({ id => $id });
        unless ($design->as_hash->{type} eq 'gibson-deletion' || $design->as_hash->{type} eq 'gibson' ) {
            $c->stash->{error_msg} = 'Please enter a valid gibson-deletion design';
            return;
        }
        my $gibsons = $c->model('Golgi')->schema->resultset('Design')->search({ parent_id => $id });
        while (my $gibson = $gibsons->next) {
            $c->stash->{error_msg} = 'Design ' . $id . ' has already been converted: ' . $gibson->as_hash->{id};
            return;
        }
        &LIMS2::Model::Util::CreateDesign::convert_gibson_to_fusion($self, $c, $id);
    }

    return unless $c->request->param('gene_pick');

    my $gene_id = $c->request->param('search_gene');
    unless ( $gene_id ) {
        $c->stash( error_msg => "Please enter a gene name" );
        return;
    }

    # if user entered a exon id
    if ( $gene_id =~ qr/^ENS[A-Z]*E\d+$/ ) {
        my $exon_id = $gene_id;
        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );

        my $exon_data;
        try{
            $exon_data = $create_design_util->c_exon_target_data( $exon_id );
        }
        catch {
            $c->log->warn("Unable to find gene information for exon $exon_id");
            $c->stash( error_msg =>
                    "Unable to find gene information for exon $exon_id, make sure it is a valid ensembl exon id"
            );
            return;
        }

        $c->stash(
            gene_id         => $exon_data->{gene_id},
            ensembl_gene_id => $exon_data->{ensembl_gene_id},
            gibson_type     => 'deletion',
            five_prime_exon => $exon_id,
        );
        $c->go( 'create_gibson_design' );
    }
    else {
        # generate and display data for exon pick table
        $c->forward( 'generate_exon_pick_data' );
        return if $c->stash->{error_msg};

        $c->go( 'gibson_design_exon_pick' );
    }

    return;
}

sub gibson_design_exon_pick : Path( '/user/gibson_design_exon_pick' ) : Args(0) {
    my ( $self, $c ) = @_;
    $c->assert_user_roles( 'edit' );

    if ( $c->request->params->{pick_exons} ) {
        my $exon_picks = $c->request->params->{exon_pick};

        unless ( $exon_picks ) {
            $c->stash( error_msg => "No exons selected" );
            $c->forward( 'generate_exon_pick_data' );
            return;
        }

        my %stash_hash = (
            gene_id         => $c->request->param('gene_id'),
            ensembl_gene_id => $c->request->param('ensembl_gene_id'),
            gibson_type     => 'deletion',
        );

        # if multiple exons, its an array_ref
        if (ref($exon_picks) eq 'ARRAY') {
            $stash_hash{five_prime_exon}  = $exon_picks->[0];
            $stash_hash{three_prime_exon} = $exon_picks->[-1];
        }
        # if its not an array_ref, it is a string with a single exon
        else {
            $stash_hash{five_prime_exon} = $exon_picks;
        }

        my $ensembl_util = WebAppCommon::Util::EnsEMBL->new( species => $c->session->{selected_species} );
        my $five_prime_exon = $ensembl_util->exon_adaptor->fetch_by_stable_id( $stash_hash{five_prime_exon} );
        $stash_hash{browse_start} = $five_prime_exon->seq_region_start - 2000;
        $stash_hash{browse_end} = $five_prime_exon->seq_region_end + 2000;
        $stash_hash{chromosome} = $five_prime_exon->seq_region_name;
        $stash_hash{species} = $c->session->{selected_species};
        $stash_hash{assembly} = lc( $c->model('Golgi')->get_species_default_assembly($c->session->{selected_species}) );

        $c->stash( %stash_hash );
        $c->go( 'create_gibson_design' );
    }

    return;
}

sub generate_exon_pick_data : Private {
    my ( $self, $c ) = @_;

    $c->log->debug("Pick exon targets for gene: " . $c->request->param('search_gene') );
    try {
        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );
        my ( $gene_data, $exon_data ) = $create_design_util->exons_for_gene(
            $c->request->param('search_gene'),
            $c->request->param('show_exons'),
        );

        my $exon_ids_string = join(',', map{ $_->{id} } @{ $exon_data } );
        my @crisprs = $c->model('Golgi')->schema->resultset('ExonCrisprs')->search( {},
            {
                bind => [ '{' . $exon_ids_string . '}' ],
            }
        );

        my %crispr_count;
        foreach my $row (@crisprs) {
            ++$crispr_count{$row->ensembl_exon_id};
        }

        for my $datum ( @{ $exon_data } ) {
            $datum->{crispr_count} = $crispr_count{ $datum->{id} } || 0;
        }

        $c->stash(
            exons       => $exon_data,
            gene        => $gene_data,
            search_gene => $c->request->param('search_gene'),
            assembly    => $create_design_util->assembly_id,
            show_exons  => $c->request->param('show_exons'),
        );
    }
    catch( LIMS2::Exception $e ) {
        $c->log->warn("Problem finding gene: $e");
        $c->stash( error_msg => "Problem finding gene: $e" );
    };

    return;
}

sub design_params_ucsc : Path( '/user/design_params_ucsc') : Args {
    my ( $self, $c ) = @_;

    my $region_coords = c_get_design_region_coords($c->req->params);
    my $general_params = {
        chr_name    => $c->req->param('chr'),
        design_type => $c->req->param('design_type'),
    };
    my $params_gff = design_params_to_gff($region_coords, $general_params);

    # See docs here on info required to generate a custom annotation
    # track in UCSC browser:
    # https://genome.ucsc.edu/goldenpath/help/hgTracksHelp.html#CustomTracks
    my $gff_string = join "\n", map { $_ =~ /^#/ ? $_ : "chr".$_ } @{$params_gff};

    my $browser_options = "browser position chr".$general_params->{chr_name}
                          .":".$region_coords->{start}."-".$region_coords->{end};
    $browser_options .= "\nbrowser dense gc5BaseBw"; # show GC content track
    $browser_options .= "\ntrack name='LIMS2 design regions' visibility=full color=182,100,245";

    $c->stash(
        clade => "mammal",
        org   => $c->session->{selected_species},
        db    => ($c->session->{selected_species} eq "Human" ? "hg38" : "mm10"),
        browser_options => $browser_options,
        gff_string => $gff_string,
    );

    return;
}

sub create_gibson_design : Path( '/user/create_gibson_design' ) : Args {
    my ( $self, $c, $is_redo ) = @_;

    $c->assert_user_roles( 'edit' );

    my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
        catalyst => $c,
        model    => $c->model('Golgi'),
    );
    $c->stash( default_p3_conf => $create_design_util->c_primer3_default_config );

    if ( $is_redo && $is_redo eq 'redo' ) {
        # if we have redo flag all the stash variables have been setup correctly
        return;
    }
    elsif ( exists $c->request->params->{create_design} ) {
        $self->_create_design( $c, $create_design_util, 'create_exon_target_design' );
    }

    return;
}

sub create_custom_target_gibson_design : Path( '/user/create_custom_target_gibson_design' ) : Args {
    my ( $self, $c, $is_redo ) = @_;

    $c->assert_user_roles( 'edit' );

    my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
        catalyst => $c,
        model    => $c->model('Golgi'),
    );
    $c->stash( default_p3_conf => $create_design_util->c_primer3_default_config );

    if ( $is_redo && $is_redo eq 'redo' ) {
        # if we have redo flag all the stash variables have been setup correctly
        return;
    }
    elsif ( exists $c->request->params->{create_design} ) {
        $self->_create_design( $c, $create_design_util, 'create_custom_target_design' );
    }
    elsif ( exists $c->request->params->{target_from_exons} ) {
        my $target_data = $create_design_util->c_target_params_from_exons;
        $c->stash(
            gibson_type => 'deletion',
            %{ $target_data },
        );
    }

    return;
}

sub _create_design {
    my ( $self, $c, $create_design_util, $cmd ) = @_;

    $c->log->info('Creating new design');

    my ($design_attempt, $job_id);
    $c->stash( $c->request->params );
    try {
        ( $design_attempt, $job_id ) = $create_design_util->$cmd;
    }
    catch ( LIMS2::Exception::Validation $err ) {
        my $errors = $create_design_util->c_format_validation_errors( $err );
        $c->log->warn( 'User create design error: ' . $errors );
        $c->stash( error_msg => $errors );
        return;
    }
    catch ($err) {
        $c->log->warn( "Error submitting design job: $err " );
        $c->stash( error_msg => "Error submitting Design Creation job: $err" );
        return;
    }

    unless ( $job_id ) {
        $c->log->warn( 'Unable to submit Design Creation job' );
        $c->stash( error_msg => "Unable to submit Design Creation job" );
        return;
    }

    $c->res->redirect( $c->uri_for('/user/design_attempt', $design_attempt->id , 'pending') );

    return;
}

sub design_attempts :Path( '/user/design_attempts' ) : Args(0) {
    my ( $self, $c ) = @_;

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
            ->c_retrieve_design_attempt( { id => $design_attempt_id, species => $species_id } );
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

    my $da = $c->stash->{da};
    my $da_hash = $da->as_hash( { json_as_hash => 1 } );

    $c->stash(
        da     => $da->as_hash( { pretty_print_json => 1 } ),
        fail   => $da_hash->{fail},
        params => $da_hash->{design_parameters},
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

## no critic(RequireFinalReturn)
sub redo_design_attempt : PathPart('redo') Chained('design_attempt') : Args(0) {
    my ( $self, $c ) = @_;

    my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
        catalyst => $c,
        model    => $c->model('Golgi'),
    );

    my $gibson_target_type;
    try {
        # this will stash all the needed design parameters
        $gibson_target_type = $create_design_util->c_redo_design_attempt( $c->stash->{da} );
    }
    catch ( $err ) {
        $c->stash(error_msg => "Error processing parameters from design attempt "
                . $c->stash->{da}->id . ":\n" . $err
                . "Unable to redo design" );
        return $c->go('design_attempts');
    }

    if ( $gibson_target_type eq 'exon' ) {
        return $c->go( 'create_gibson_design', [ 'redo' ] );
    }
    elsif ( $gibson_target_type eq 'location' ) {
        return $c->go( 'create_custom_target_gibson_design' , [ 'redo' ] );
    }
    else {
        $c->stash( error_msg => "Unknown gibson target type $gibson_target_type"  );
        return $c->go('design_attempts');
    }

    return;
}
## use critic

sub wge_design_importer :Path( '/user/wge_design_importer' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    if ( $c->request->param('import_design') ) {

        my $client = LIMS2::REST::Client->new_with_config(
            configfile => $ENV{WGE_REST_CLIENT_CONFIG}
        );
        my $design_id = $c->request->param('design_id');

        $c->log->info("wge_design_importer: Importing WGE design: $design_id");

        my $design_data = $client->GET( 'design', { id => $design_id, supress_relations => 0 } );

        my $species = $design_data->{species};
        if ( $c->session->{selected_species} ne $species ) {
            $c->stash( error_msg => "LIMS2 is set to ".$c->session->{selected_species}." and design is "
                .$design_data->{species}.".\n" . "Plese switch to the correct species in LIMS2." );
            return;
        }

        my $species_default_assembly_id = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
                { species_id => $species } )->assembly_id;
        my $design_assembly_id = $design_data->{oligos}[0]{locus}{assembly};
        if ( $species_default_assembly_id ne $design_assembly_id ) {
            $c->stash( error_msg => "LIMS2 is on the $species_default_assembly_id $species assembly "
                    . "and this design is on $design_assembly_id assembly, unable to import" );
            return;
        }

        $design_data->{created_by} = $c->user->name;
        $design_data->{oligos} = [ map { {loci => [ $_->{locus} ], seq => $_->{seq}, type => $_->{type} } } @{ $design_data->{oligos} } ];
        $design_data->{gene_ids} = [ map { $c->model('Golgi')->find_gene({ species => $design_data->{species}, search_term => $_ }) } @{ $design_data->{assigned_genes} } ];

        my $gene_type_id;
        if ($design_data->{species} eq 'Mouse') { $gene_type_id = 'MGI' };
        if ($design_data->{species} eq 'Human') { $gene_type_id = 'HGNC' };
        for (my $i=0; $i < scalar @{$design_data->{gene_ids}}; $i++ ) {
            @{$design_data->{gene_ids}}[$i]->{gene_type_id} = $gene_type_id;
        }

        delete $design_data->{assigned_genes};
        delete $design_data->{oligos_fasta};
        delete $design_data->{strand};
        delete $design_data->{oligo_order_seqs};
        delete $design_data->{assembly};
        foreach my $comments (@{$design_data->{comments}}) {
            delete $comments->{id};
        }

        $design_data->{id} = $design_id;

        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );

        $c->model('Golgi')->txn_do( sub {
            try{
                my $design = $c->model('Golgi')->c_create_design( $design_data );
                my $build = $DEFAULT_SPECIES_BUILD{ lc($species) };

                foreach my $gene ( @{ $design_data->{gene_ids} }) {
                    $create_design_util->calculate_design_targets( {
                        ensembl_gene_id => $gene->{ensembl_id},
                        gene_id         => $gene->{gene_id},
                        target_start    => $design->target_region_start,
                        target_end      => $design->target_region_end,
                        chr_name        => $design->chr_name,
                        user            => $design_data->{created_by},
                        species         => $species,
                        build_id        => $build,
                        assembly_id     => $species_default_assembly_id,
                    } );
                }
                $c->log->info( "wge_design_importer: Successfull design creation with id $design_id" );
                $c->stash( success_msg => "Successfully imported from WGE design with id $design_id" );
            }
            catch ($err) {
                $c->log->info("wge_design_importer: Unable to create design: $err");
                $c->stash( error_msg => "Error importing WGE design: $err" );
                $c->model('Golgi')->txn_rollback;
                return;
            }
            $c->stash( design_id => $design_id );
        });
    }

    return;
}

sub create_point_mutation_design :Path( '/user/create_point_mutation_design' ) : Args(0){
    my ($self, $c ) = @_;

    if($c->req->param('submit')){
        my $design_params = { slice_def $c->req->params(), qw(oligo_sequence chr_start chr_end chr_strand chr_name) };
        $c->stash( $design_params );

        $design_params->{species} = $c->session->{selected_species};
        $design_params->{type} = 'point-mutation';

        my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
            catalyst => $c,
            model    => $c->model('Golgi'),
        );

        try{
            my $design = $create_design_util->create_point_mutation_design( $design_params );
            if($design){
                $c->flash->{success_msg} = ('Point mutation design created');
                $c->res->redirect( $c->uri_for('/user/view_design', { design_id => $design->id }) );
                return;
            }
        }
        catch ($err){
            $c->stash->{error_msg} = "Design creation failed: $err";
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
