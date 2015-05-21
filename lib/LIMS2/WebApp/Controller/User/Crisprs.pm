package LIMS2::WebApp::Controller::User::Crisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Crisprs::VERSION = '0.318';
}
## use critic


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

use LIMS2::Model::Util::CreateDesign;
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD %GENE_TYPE_REGEX);
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

    if($crispr_entity){
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
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }
    catch( LIMS2::Exception::NotFound $e ) {
        $c->stash( error_msg => "Crispr $crispr_id not found" );
        return $c->go( 'Controller::User::DesignTargets', 'index' );
    }

    $c->log->debug( "Retrived crispr: $crispr_id" );

    $c->stash(
        crispr  => $crispr,
        species => $species_id,
    );

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

    $c->stash(
        crispr_data             => $crispr->as_hash,
        ots                     => \@off_target_summaries,
        designs                 => [ $crispr->crispr_designs->all ],
        linked_nonsense_crisprs => $crispr->linked_nonsense_crisprs,
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

    $c->stash(
        ots            => $off_target_summary,
        designs        => [ $crispr_pair->crispr_designs->all ],
        crispr_primers => $cp_data->{crispr_primers},
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
            output_dir => dir( '/lustre/scratch109/sanger/team87/crispr_logs' ),
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
        $error = "You must provide and gene ID for this crispr group";
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

__PACKAGE__->meta->make_immutable;

1;
