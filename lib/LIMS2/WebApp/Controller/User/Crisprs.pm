package LIMS2::WebApp::Controller::User::Crisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Crisprs::VERSION = '0.129';
}
## use critic

use Moose;
use TryCatch;
use LIMS2::Model::Constants qw( %UCSC_BLAT_DB );
use YAML::Any;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

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

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
