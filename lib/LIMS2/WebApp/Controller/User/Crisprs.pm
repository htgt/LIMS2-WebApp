package LIMS2::WebApp::Controller::User::Crisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Crisprs::VERSION = '0.189';
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

use LIMS2::Model::Util::CreateDesign;
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );

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

sub index : Path( '/user/browse_crisprs' ) : Args(0) {
    my ( $self, $c ) = @_;

    # TODO, add crispr search page here?

    return;
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
        crispr_data  => $crispr->as_hash,
        ots          => \@off_target_summaries,
        designs      => [ $crispr->crispr_designs->all ],
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
        uscs_db  => $ucsc_db,
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

    $c->stash(
        ots     => $off_target_summary,
        designs => [ $crispr_pair->crispr_designs->all ],
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
        uscs_db  => $ucsc_db,
    );

    return;
}


=head for genoverse browser
=cut

sub browse_crisprs : Path( '/user/browse_crisprs' ) : Args(0) {
        my ( $self, $c ) = @_;

        return;
    }

sub browse_crisprs_genoverse : Path( '/user/browse_crisprs_genoverse' ) : Args(0) {
        my ( $self, $c ) = @_;

        return;
    }

=head genoverse_browse_view
Given
    genome
    chromosome ID
    symbol
    gene_id
    exon_id
Renders
    genoverse_browse_view
With
    genome
    chromosome ID
    symbol
    gene_id
    exon_id
    exon_start (chromosome coordinates)
    exon_end (chromosome coordinates)
=cut

sub genoverse_browse_view : Path( '/user/genoverse_browse' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $exon_coords_rs = $c->model('Golgi')->schema->resultset('DesignTarget')->search(
        {
            'ensembl_exon_id' => $c->request->params->{'exon_id'},
        }
    );

    my $exon_coords = $exon_coords_rs->single;
    $c->stash(
        'genome'        => $c->request->params->{'genome'},
        'chromosome'    => $c->request->params->{'chromosome'},
        'gene_symbol'   => $c->request->params->{'symbol'},
        'gene_id'       => $c->request->params->{'gene_id'},
        'exon_id'       => $c->request->params->{'exon_id'},
        'exon_start'    => $exon_coords->chr_start,
        'exon_end'      => $exon_coords->chr_end,
        'view_single'   => $c->request->params->{'view_single'},
        'view_paired'   => $c->request->params->{'view_paired'},
    );

    return;
}

sub get_crisprs : Path( '/user/get_crisprs' ) : Args(0) {
    my ( $self, $c ) = @_;

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


sub wge_crispr_importer :Path( '/user/wge_crispr_importer' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    if ( $c->request->param('import_crispr') ) {

        my $client = LIMS2::REST::Client->new_with_config(
            configfile => $ENV{WGE_REST_CLIENT_CONFIG}
        );
        my $wge_crispr_id = $c->request->param('wge_cripr_id');

        my $crispr_data = $client->GET( 'crispr', { id => $wge_crispr_id } );
        my $species = $client->GET( 'get_all_species');

        $crispr_data->{species} = $species->{$crispr_data->{species_id}};

        if ( $c->session->{selected_species} ne $crispr_data->{species} ) {
            $c->stash( error_msg => "LIMS2 is set to ".$c->session->{selected_species}." and crispr is "
                .$crispr_data->{species}.".\n" . "Plese switch to the correct species in LIMS2." );
            return;
        }

        # for now, algorithm is always bwa and type is always exonic. should be variable...
        $crispr_data->{off_target_algorithm} = 'bwa';
        $crispr_data->{type} = 'Exonic';

        $crispr_data->{wge_crispr_id} = $crispr_data->{id};
        $crispr_data->{locus} = {
            chr_name  => $crispr_data->{chr_name},
            chr_start => $crispr_data->{chr_start},
            chr_end   => $crispr_data->{chr_end},
        };

        $crispr_data->{pam_right} ? $crispr_data->{locus}->{chr_strand} = 1 : $crispr_data->{locus}->{chr_strand} = -1;

        my $assembly = $c->model('Golgi')->schema->resultset('SpeciesDefaultAssembly')->find(
            { species_id => $crispr_data->{species} } )->assembly_id;

        $crispr_data->{locus}->{assembly} = $assembly;

        delete $crispr_data->{id};
        delete $crispr_data->{species_id};
        delete $crispr_data->{chr_name};
        delete $crispr_data->{chr_start};
        delete $crispr_data->{chr_end};

        my $crispr;

        try {
            $crispr = $c->model('Golgi')->create_crispr( $crispr_data );
            $c->stash( success_msg => "Successfully imported from WGE crispr with id $wge_crispr_id" );
        }
        catch ($err) {
            $c->stash( error_msg => "Error importing WGE design: $err" );
            return;
        }

        $c->stash(
            crispr_id => $crispr->id,
        );
    }

    return;
}




__PACKAGE__->meta->make_immutable;

1;
