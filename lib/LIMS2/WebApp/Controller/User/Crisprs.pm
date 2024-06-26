package LIMS2::WebApp::Controller::User::Crisprs;

use Moose;
use TryCatch;
use LIMS2::Model::Constants qw( %UCSC_BLAT_DB );
use YAML::Any;
use namespace::autoclean;
use Path::Class;
use JSON;
use List::MoreUtils qw( uniq );
use Data::Dumper;
use Hash::MoreUtils qw( slice_def );

use LIMS2::Model::Util::Crisprs qw( gene_ids_for_crispr crispr_groups_for_crispr crispr_pairs_for_crispr crispr_wells_for_crispr );
use LIMS2::Util::QcPrimers;
use LIMS2::Model::Util::CreateDesign;
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD %GENE_TYPE_REGEX);
use LIMS2::Model::Util::CrisprOrderAndStorage;
BEGIN { extends 'Catalyst::Controller' };

with qw(
MooseX::Log::Log4perl
WebAppCommon::Crispr::SubmitInterface
);

=head1 NAME

LIMS2::WebApp::Controller::User::Crisprs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub search_crisprs : Path( '/user/search_crisprs' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    foreach my $item ( qw(crispr_id crispr_pair_id crispr_group_id wge_crispr_id) ){
        if(my $value = $c->req->param($item)){
            $c->stash->{$item} = $value;
        }
    }
    my $crispr_entity;
    if($c->req->param('search_by_lims2_id')){
        my $params = {
            slice_def($c->req->params, qw(crispr_id crispr_pair_id crispr_group_id))
        };
        try{
            $crispr_entity = $c->model('Golgi')->retrieve_crispr_collection($params);
        }
        catch($e){
            $c->stash->{error_msg} = "Failed to find crisprs in LIMS2: $e";
        };
    }
    elsif($c->req->param('search_by_wge_id')){
        # NB: cannot search by WGE crispr pair ID because, although we use this
        # when importing, we only store the individual WGE crispr IDs in lims2
        try{
            $crispr_entity = $c->model('Golgi')->retrieve_crispr({
                wge_crispr_id => $c->req->param('wge_crispr_id')
            });
        }
        catch($e){
            $c->stash->{error_msg} = "Failed to find WGE crispr in LIMS2: $e";
        }
    }
    elsif($c->req->param('search_by_sequence')){
        sequence_search($self, $c);
    }
    if($crispr_entity){
        if ($species_id ne $crispr_entity->species_id) {
            $c->stash->{error_msg} = "Crispr does not seem to be for $species_id. Please switch species.";
            return;
        }
        my $redirect_path = _path_for_crispr_entity($crispr_entity);
        $c->res->redirect( $c->uri_for($redirect_path) );
    }
    return;
}

sub _path_for_crispr_entity{
    my ($crispr_entity) = @_;

    my $entity_type = $crispr_entity->id_column_name;
    $entity_type =~ s/_id//;

    my $path = "/user/$entity_type/".$crispr_entity->id."/view";
    return $path;
}

=head2 crispr

=cut
sub crispr : PathPart('user/crispr') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $crispr_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my $crispr;
    try {
        $crispr = $c->model('Golgi')->retrieve_crispr( { id => $crispr_id, species => $species_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid crispr id" );
        return $c->go( 'search_crisprs' );
    }
    catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Crispr $crispr_id not found" );
        return $c->go( 'search_crisprs' );
    }

    $c->log->debug( "Retrieved crispr: $crispr_id" );
    if($c->request->param('generate_primers')){

        $c->assert_user_roles( 'edit' );

        _generate_primers_for_crispr_entity($c, $crispr);
    }

    $c->stash->{crispr} = $crispr;
    $c->stash->{species} = $species_id;

    return;
}

# Should be able to use the same generation method for crisprs, groups and pairs
sub _generate_primers_for_crispr_entity{
    my ($c, $crispr_entity) = @_;
    my $id_type = $crispr_entity->id_column_name;

    if($crispr_entity->crispr_primers->all){
        $c->stash->{info_msg} = "Already has primers. Ignoring generate primers request";
    }
    else{
        $ENV{LIMS2_PRIMER_DIR} or die "LIMS2_PRIMER_DIR environment variable not set";
        my $primer_dir = dir( $ENV{LIMS2_PRIMER_DIR} );
        my $job_id = Data::UUID->new->create_str();
        my $base_dir = $primer_dir->subdir( $job_id );
        $base_dir->mkpath;

        my $primer_util = LIMS2::Util::QcPrimers->new({
            primer_project_name => 'crispr_sequencing',
            model               => $c->model('Golgi'),
            base_dir            => "$base_dir",
            persist_primers     => 1,
            overwrite           => 0,
            run_on_farm         => 0,
        });

        my $pcr_primer_util = LIMS2::Util::QcPrimers->new({
            primer_project_name => 'crispr_pcr',
            model               => $c->model('Golgi'),
            base_dir            => "$base_dir",
            persist_primers     => 1,
            overwrite           => 0,
            run_on_farm         => 0,
        });

        try{
            $c->log->debug("Generating primers for $id_type ".$crispr_entity->id);
            my ($picked_primers, $seq, $db_primers) = $primer_util->crispr_sequencing_primers($crispr_entity);
            if($picked_primers){
                my ($pcr_picked_primers, $pcr_seq, $pcr_db_primers)
                    = $pcr_primer_util->crispr_PCR_primers($picked_primers, $crispr_entity);
                $c->stash->{info_msg} = "Primers generated for $id_type ".$crispr_entity->id;
            }
            else{
                $c->stash->{error_msg} = "Failed to generate primers for $id_type ".$crispr_entity->id;
            }

        }
        catch($e){
            $c->stash->{error_msg} = $e;
        }
        $crispr_entity->discard_changes;
    }
    return;
}

=head2 view_crispr

=cut
sub view_crispr : PathPart('view') Chained('crispr') : Args(0) {
    my ( $self, $c ) = @_;
    my $crispr = $c->stash->{crispr};

    my @off_target_summaries;
    for my $ots ( $crispr->off_target_summaries->all ) {
        my $summary = Load( $ots->summary );
        push @off_target_summaries, {
            outlier   => $ots->outlier,
            algorithm => $ots->algorithm,
            summary   => $summary,
        }
    }

    my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); }; #gene finder method
    my @gene_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr, $c->model('Golgi') ) };

    my @genes;
    for my $gene_id ( @gene_ids ) {
        try {
            my $gene = $c->model('Golgi')->find_gene( { species => $c->stash->{species}, search_term => $gene_id } );
            push @genes, { 'gene_symbol' => $gene->{gene_symbol}, 'gene_id' => $gene_id };
        };
    }

    my @pairs = crispr_pairs_for_crispr( $c->model('Golgi')->schema, { crispr_id => $crispr->id } );
    my @groups = crispr_groups_for_crispr( $c->model('Golgi')->schema, { crispr_id => $crispr->id } );
    my @wells = crispr_wells_for_crispr( $c->model('Golgi')->schema, { crispr_id => $crispr->id } );

    my $storage_instance = LIMS2::Model::Util::CrisprOrderAndStorage->new({ model => $c->model('Golgi') });
    my @crispr_locations = $storage_instance->locate_crispr_in_store($crispr->id);

    $c->stash(
        crispr_data             => $crispr->as_hash,
        ots                     => \@off_target_summaries,
        designs                 => [ $crispr->crispr_designs->all ],
        pairs                   => [ map{ $_->as_hash } @pairs ],
        groups                  => [ map{ $_->as_hash } @groups ],
        linked_nonsense_crisprs => $crispr->linked_nonsense_crisprs,
        genes                   => \@genes,
        wells                   => [ map{ $_->as_hash } @wells ],
        crispr_locations        => \@crispr_locations,
    );

    return;
}

=head2 crispr_ucsc_blat

Link to UCSC Blat page for set for crisprs for a design target.

=cut
sub crispr_ucsc_blat : PathPart('blat') Chained('crispr') : Args(0) {
    my ( $self, $c ) = @_;

    my $crispr = $c->stash->{crispr};
    my $ucsc_db = $UCSC_BLAT_DB{ lc($c->stash->{species}) };
    my $blat_seq = '>' . $crispr->id . "\n" . $crispr->seq;

    $c->stash(
        sequence => $blat_seq,
        ucsc_db  => $ucsc_db,
    );

    return;
}

=head2 crispr_pair

=cut
sub crispr_pair : PathPart('user/crispr_pair') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $crispr_pair_id ) = @_;
    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my $crispr_pair;
    try {
        $crispr_pair = $c->model('Golgi')->retrieve_crispr_pair( { id => $crispr_pair_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid crispr pair id" );
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }
    catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Crispr Pair $crispr_pair_id not found" );
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }

    $c->log->debug( "Retrived crispr pair: $crispr_pair_id" );

    if($c->request->param('generate_primers')){

        $c->assert_user_roles( 'edit' );

        _generate_primers_for_crispr_entity($c, $crispr_pair);
    }
    $c->stash(
        cp           => $crispr_pair,
        left_crispr  => $crispr_pair->left_crispr->as_hash,
        right_crispr => $crispr_pair->right_crispr->as_hash,
        species      => $species_id,
    );

    return;
}

=head2 view_crispr_pair

=cut
sub view_crispr_pair : PathPart('view') Chained('crispr_pair') Args(0) {
    my ( $self, $c ) = @_;
    my $crispr_pair = $c->stash->{cp};
    my $off_target_summary = Load( $crispr_pair->off_target_summary );
    my $cp_data = $crispr_pair->as_hash;

    my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); }; #gene finder method
    my @gene_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr_pair, $c->model('Golgi') ) };

    my @genes;
    for my $gene_id ( @gene_ids ) {
        try {
            my $gene = $c->model('Golgi')->find_gene( { species => $c->stash->{species}, search_term => $gene_id } );
            push @genes, { 'gene_symbol' => $gene->{gene_symbol}, 'gene_id' => $gene_id };
        };
    }

    $c->stash(
        ots            => $off_target_summary,
        designs        => [ $crispr_pair->crispr_designs->all ],
        crispr_primers => $cp_data->{crispr_primers},
        genes          => \@genes,
    );

    return;
}

=head2 crispr_pair_ucsc_blat

Link to UCSC Blat page for set for crisprs for a design target.

=cut
sub crispr_pair_ucsc_blat : PathPart('blat') Chained('crispr_pair') : Args(0) {
    my ( $self, $c ) = @_;

    my $cp = $c->stash->{cp};
    my $ucsc_db = $UCSC_BLAT_DB{ lc($c->stash->{species}) };
    my $blat_seq = '>' . $cp->id . "\n" . $cp->left_crispr->seq . $cp->right_crispr->seq;

    $c->stash(
        sequence => $blat_seq,
        ucsc_db  => $ucsc_db,
    );

    return;
}

sub crispr_group : PathPart('user/crispr_group') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $crispr_group_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my $crispr_group;
    try {
        $crispr_group = $c->model('Golgi')->retrieve_crispr_group( { id => $crispr_group_id } );
    }
    catch( LIMS2::Exception::Validation $e ) {
        $c->stash( error_msg => "Please enter a valid crispr group id" );
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }
    catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Crispr Group $crispr_group_id not found" );
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }

    $c->log->debug( "Retrived crispr group: $crispr_group_id" );

    if($c->request->param('generate_primers')){
        $c->assert_user_roles( 'edit' );
        _generate_primers_for_crispr_entity($c, $crispr_group);
    }
    my $crispr_hash = $crispr_group->as_hash;
    $crispr_group->{gene_symbol} = $c->model('Golgi')->retrieve_gene({
            species => $crispr_hash->{group_crisprs}[0]->{species},
            search_term => $crispr_hash->{gene_id},
    })->{gene_symbol};

    $c->stash(
        cg           => $crispr_group,
        group_crisprs => [ map { $_->as_hash } $crispr_group->crispr_group_crisprs ],
        species      => $species_id,
    );

    return;
}

=head2 view_crispr_pair

=cut
sub view_crispr_group : PathPart('view') Chained('crispr_group') Args(0) {
    my ( $self, $c ) = @_;
    my $crispr_group = $c->stash->{cg};
    my $cg_data = $crispr_group->as_hash;

    $c->stash(
        designs        => [ $crispr_group->crispr_designs->all ],
        crispr_primers => $cg_data->{crispr_primers},
    );

    return;
}

sub crispr_group_ucsc_blat : PathPart('blat') Chained('crispr_group') : Args(0) {
    my ( $self, $c ) = @_;

    my $cg = $c->stash->{cg};
    my $ucsc_db = $UCSC_BLAT_DB{ lc($c->stash->{species}) };
    my $blat_seq = '>' . "Crispr_Group_" . $cg->id . "\n";
    my $crispr_seq = join "", map { $_->seq } $cg->crisprs;
    $blat_seq .= $crispr_seq;

    $c->stash(
        sequence => $blat_seq,
        ucsc_db  => $ucsc_db,
    );

    return;
}

sub get_crisprs : Path( '/user/get_crisprs' ) : Args(0) {
    my ( $self, $c ) = @_;

    LIMS2::Exception->throw( 'This method is deprecated -- please use WGE for off targets.' );

    my $job_id;

    my %stash_data = (
        template => 'user/crisprs/get_crisprs.tt',
        exon_id  => $c->request->param('exon_id'),
        gene_id  => $c->request->param('gene_id'),
        species  => $c->session->{selected_species},
    );

    my $assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $c->session->{selected_species} } )->assembly_id;

    my $params = {
        species         => $c->session->{selected_species},
        exon_id         => $c->request->param('exon_id'),
        ensembl_gene_id => $c->request->param('ensembl_gene_id'),
        gene_id         => $c->request->param('gene_id'),
        build_id        => $DEFAULT_SPECIES_BUILD{ lc($c->session->{selected_species}) },
        assembly_id     => $assembly,
        user            => $c->user->name,
    };

    my $create_design_util = LIMS2::Model::Util::CreateDesign->new(
        catalyst => $c,
        model    => $c->model('Golgi'),
    );

    my $design_target  = $create_design_util->find_or_create_design_target( $params );

    try {

        my $cmd = [
        "/nfs/team87/farm3_lims2_vms/software/Crisprs/paired_crisprs_lims2.sh",
            $c->request->param('exon_id'),
            $c->session->{selected_species},
            $c->request->param('exon_id'),
        ];

        my $bsub_params = {
            output_dir => dir( '/lustre/scratch125/sciops/team87/crispr_logs' ),
            id         => $c->request->param('exon_id'),
        };

        #we need to provide $self->log for this to work
        $job_id = $self->c_run_crispr_search_cmd( $cmd, $bsub_params );
        $stash_data{job_id} = $job_id;
    }
    catch ($err) {
            $stash_data{error_msg} = $err;
    }

    $c->stash( %stash_data );

    return;
}

#crispr and pair importer should be served by the same method
sub wge_crispr_importer :Path( '/user/wge_crispr_importer' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    return unless $c->request->param('import_crispr');

    my @output;
    try {
        @output = $self->wge_importer(
            $c,
            'crispr'
        );
    }
    catch ( $err ) {
        $c->stash( error_msg => "$err" );
        return;
    }

    if ( @output ) {
        $c->stash( success_msg => "Successfully imported the following WGE ids:\n"
                                . join ', ', map { $_->{wge_id} } @output );
    }
    $c->stash(
        crispr => \@output,
    );
    generate_on_import($self,$c,"single",@output);
    return;
}

#identical but 1 line to the above function, should be merged
sub wge_crispr_pair_importer :Path( '/user/wge_crispr_pair_importer' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return unless $c->request->param('import_crispr');

    my @output;
    try {
        @output = $self->wge_importer(
            $c,
            'pair'
        );
    }
    catch ( $err ) {
        $c->stash( error_msg => "$err" );
        return;
    }

    if ( @output ) {
        $c->stash( success_msg => "Successfully imported the following WGE pair ids:\n"
                                . join ', ', map { $_->{wge_id} } @output );
    }

    $c->stash(
        crispr => \@output,
    );
    generate_on_import($self,$c,"pair",@output);

    return;
}

sub wge_crispr_group_importer :Path( '/user/wge_crispr_group_importer' ) : Args(0) {
    my ( $self, $c ) = @_;
    $c->log->debug( 'Attempting to import crispr group' );
    $c->assert_user_roles( 'edit' );

    my @gene_types = map { $_->id } $c->model('Golgi')->schema->resultset('GeneType')->all;
    $c->stash->{gene_types} = \@gene_types;

    return unless $c->request->param('import_crispr_group');

    # Check the gene input here
    # wge_importer will check wge_crispr_id fields
    my ($error, $type_id);
    my $gene_id = $c->req->param('gene_id');
    my $species = $c->session->{selected_species};

    if ($species eq 'Mouse') {
        $type_id = 'MGI'
    }
    elsif ($species eq 'Human') {
        $type_id = 'HGNC'
    }

    if( $gene_id and $type_id ){
        if(my $regex = $GENE_TYPE_REGEX{ $type_id }){
            unless($gene_id =~ $regex){
                $error = "Gene ID $gene_id does not look like a $species gene";
            }
        }
        my $gene = $c->model('Golgi')->find_gene( { search_term => $gene_id, species => $species } );
        if ($gene->{gene_symbol} eq 'unknown') {
            $error = "Gene ID $gene_id does not seem to be valid";
        }
    }
    else{
        $error = "You must provide a gene ID for this crispr group";
    }

    if($error){
        $c->stash->{error_msg} = $error;
        _stash_crispr_group_importer_input($c);
        return;
    }

    my @output;
    try {
        @output = $self->wge_importer(
            $c,
            'group'
        );
    }
    catch ( $err ) {
        $c->stash( error_msg => "$err" );
        _stash_crispr_group_importer_input($c);
        return;
    }

    if ( @output ) {
        $c->stash->{success_msg} = "Successfully imported the following WGE ids: "
                                  . join ', ', map { $_->{wge_id} } @output ;
    }
    else{
        $c->log->debug("No output from wge_importer");
        _stash_crispr_group_importer_input($c);
        return;
    }

    # Create array of { lims2 crispr ids and left_of_target boolean }
    my @crisprs;
    my @wge_left_ids = split /[,\s]+/, $c->req->param('wge_crispr_id_left');
    $c->log->debug("left crispr IDs: @wge_left_ids");
    foreach my $crispr_info (@output){
        my $left_of_target = ( grep { $_ == $crispr_info->{wge_id} } @wge_left_ids ) ? 1 : 0 ;
        push @crisprs, { crispr_id => $crispr_info->{lims2_id}, left_of_target => $left_of_target };
    }

    my $group;
    try{
        $group = $c->model('Golgi')->create_crispr_group({
            gene_id      => $gene_id,
            gene_type_id => $type_id,
            crisprs      => \@crisprs,
        });
    }
    catch( $err ){
        $c->stash( error_msg => "$err" );
        _stash_crispr_group_importer_input($c);
        return;
    }

    $c->stash(
        group  => $group->as_hash,
    );

    #Convert the lims2 id string into the same format as single and pair importation
    my @lims2_group;
    my $lims2_conversion_id = {
        lims2_id => $group->as_hash->{id},
    };
    push(@lims2_group,$lims2_conversion_id);

    generate_on_import($self,$c,"group",@lims2_group);

    return;
}

sub _stash_crispr_group_importer_input{
    my ( $c ) = @_;

    my @input_names = qw(gene_id gene_type_id wge_crispr_id_left wge_crispr_id_right);
    foreach my $name (@input_names){
        if(my $value = $c->req->param($name)){
            $c->log->debug("stashing value \"$value\" param $name");
            $c->stash->{$name} = $value;
        }
    }
    return;
}

#generic function to import crisprs or pairs to avoid duplication
sub wge_importer {
    my ( $self, $c, $type ) = @_;

    my ( $method, $user_input );
    if ( $type =~ /^crispr/ ) {
        $method     = 'import_wge_crisprs';
        $user_input = $c->request->param('wge_crispr_id')
            or die "No crispr IDs provided";
    }
    elsif ( $type =~ /^pair/ ) {
        $method     = 'import_wge_pairs';
        $user_input = $c->request->param('wge_crispr_pair_id')
            or die "No crispr pair IDs provided";
    }
    elsif ( $type =~ /^group/ ){
        $method     = 'import_wge_crisprs';
        my $left_ids = $c->request->param('wge_crispr_id_left')
            or die "No left of target crispr IDs provided";
        my $right_ids = $c->request->param('wge_crispr_id_right')
            or die "No right of target crispr IDs provided";
        $user_input = join ",", $left_ids, $right_ids;
    }
    else {
        LIMS2::Exception->throw( "Unknown importer type: $type" );
    }

    my $species = $c->session->{selected_species};
    my $assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species }
    )->assembly_id;

    my @ids = split /[,\s]+/, $user_input;

    my @output = $c->model('Golgi')->$method( \@ids, $species, $assembly );

    return @output;
}

#After the crisprs have been imported from WGE, retrieve the crispr entities.
sub generate_on_import {
    my ( $self, $c, $instance, @wge_crisprs) = @_;
    my @lims2_ids;

    foreach my $crispr (@wge_crisprs){
        push(@lims2_ids, $crispr->{lims2_id});
    }

    my $crispr_entity;
    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    #Depending on the type of crispr, retrieve the crispr entity in one of the following ways.
    foreach my $crispr_id (@lims2_ids)
    {
        if ($instance eq "single"){
            $crispr_entity = $c->model('Golgi')->retrieve_crispr( { id => $crispr_id, species => $species_id } );
        }
        elsif ($instance eq "pair"){
            $crispr_entity = $c->model('Golgi')->retrieve_crispr_pair( { id => $crispr_id } );
        }
        elsif ($instance eq "group") {
            $crispr_entity = $c->model('Golgi')->retrieve_crispr_group( { id => $crispr_id } );
        }
        #Pass the crispr entities for primer generation
        _generate_primers_for_crispr_entity($c, $crispr_entity);
    }

    return;
}

sub sequence_search {
    my ($self, $c) = @_;
    my $sequence = $c->req->param('sequence');
    $sequence = uc $sequence;
    my $count = length($sequence);
    if ( $count > 23) {
        $c->stash->{info_msg} = "Please provide 23 or less base sequence, you provided ". $count;
        return;
    }
    elsif ( $sequence =~ qr/^[ACTG]+$/ ){
        my $species = $c->session->{selected_species};

        my @crisprs = $c->model('Golgi')->schema->resultset('Crispr')->search({
            seq => {'like', "%".$sequence."%"},
            species_id => $species,
        },
        {
            distinct => 1,
            columns => [qw/
                id
                seq
                species_id
                crispr_loci_type_id
            /],
        }
        );
        if (@crisprs){
            $c->stash(
                crispr => \@crisprs,
                original => $sequence,
            );
        }
        else {
             $c->stash->{info_msg} = "No crispr were found with the sequence pattern: ". $sequence;
        }
        return
    }
    else {
        $c->stash->{info_msg} = "Not a valid sequence, please check for invalid bases.";
        return;
    }

}

__PACKAGE__->meta->make_immutable;

1;
