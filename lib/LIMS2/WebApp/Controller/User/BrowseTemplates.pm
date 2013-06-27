package LIMS2::WebApp::Controller::User::BrowseTemplates;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::BrowseTemplates::VERSION = '0.084';
}
## use critic

use Moose;
use LIMS2::WebApp::Pageset;
use JSON;
use Try::Tiny;
use List::MoreUtils qw( uniq );
use LIMS2::Model::Util::EngSeqParams qw(generate_genbank_for_qc_well);
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::BrowseTemplates - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path( '/user/browse_templates' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    if ( $params->{show_all} ) {
        delete @{$params}{ qw( show_all template_name ) };
    }

    my ( $templates, $pager ) = $c->model('Golgi')->list_templates(
        {
            template_name => $params->{template_name},
            species       => $params->{species} || $c->session->{selected_species},
            page          => $params->{page},
            pagesize      => $params->{pagesize}
        }
    );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->uri_for( '/user/browse_templates', $params )
        }
    );

    $c->stash(
        template_name       => $params->{template_name},
        templates           => $templates,
        pageset             => $pageset
    );

    return;
}

sub view :Path( '/user/view_template' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $params = $c->request->params;

    # Download genbank for well if requested
    if (my $well_id = $params->{genbank_well_id}){
    	$self->_download_genbank_for_qc_well($c, $well_id);
    	return;
    }

    my $template = $c->model('Golgi')->retrieve_qc_template( $c->request->params );
    my @related_runs = $template->qc_runs;
    my @run_ids = map { $_->id } @related_runs;

    my @well_info;
    foreach my $well ($template->qc_template_wells){
        my $info;
        $info->{id} = $well->id;
        $info->{well_name} = $well->name;

        my $es_params = decode_json($well->qc_eng_seq->params);
        $info->{cassette} = $es_params->{insertion} ? $es_params->{insertion}->{name}
                                                    : $es_params->{u_insertion}->{name};

        $info->{backbone} = $es_params->{backbone} ? $es_params->{backbone}->{name}
                                                   : undef;

        $info->{recombinase} = $es_params->{recombinase} ? join ", ", @{$es_params->{recombinase}}
                                                         : undef;

        # Store as *_new the cassette, backbone and recombinases that
        # were specified for the qc template (rather than taken from source well)
	    if (my $cassette = $well->qc_template_well_cassette){
	    	$info->{cassette_new} = $cassette->cassette->name;
	    }
	    if (my $backbone = $well->qc_template_well_backbone){
	    	$info->{backbone_new} = $backbone->backbone->name;
	    }
	    if (my @recombinases = $well->qc_template_well_recombinases->all){
	    	# FIXME: what if some recombinases from source and some from template?
	    	$info->{recombinase_new} = join ", ", map { $_->recombinase_id } @recombinases;
	    }

	    my $genes;
        if (my $source = $well->source_well){
        	$info->{source_plate} = $source->plate->name;
        	$info->{source_well} = $source->name;
        	$info->{design_id} = $source->design->id;
        	my @gene_ids      = uniq map { $_->gene_id } $source->design->genes;
		my @gene_symbols;
		foreach my $gene_id ( @gene_ids ) {
			$genes = $c->model('Golgi')->search_genes(
                { search_term => $gene_id, species =>  $c->session->{selected_species} } );

            push @gene_symbols,  map { $_->{gene_symbol} } @{$genes || [] };
		}
        	$info->{gene_ids} = join q{/}, @gene_ids;
            $info->{gene_symbols} = join q{/}, @gene_symbols;
        }

        push @well_info, $info;
    }

    my @sorted = sort { $a->{well_name} cmp $b->{well_name} } @well_info;

    $c->stash(
        qc_template  => $template,
        wells        => \@sorted,
        qc_run_ids   => \@run_ids,
    );

    return;
}

sub delete_template :Path( '/user/delete_template') :Args(0) {
	my ($self, $c) = @_;

    my $params = $c->request->params;

    unless ( $params->{id} ) {
        $c->flash->{error_msg} = 'No template_id specified';
        $c->res->redirect( $c->uri_for('/user/browse_templates') );
        return;
    }

    $c->assert_user_roles( 'edit' );

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->delete_qc_template( { id => $params->{id}, delete_runs => 1 } );
                $c->flash->{success_msg} = 'Deleted template ' . $params->{name};
                $c->res->redirect( $c->uri_for('/user/browse_templates') );
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting template: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/view_template', { id => $params->{id} }) );
            };
        }
    );
    return;
}

sub _download_genbank_for_qc_well {
	my ($self, $c, $well_id) = @_;

    $c->assert_user_roles( 'read' );

    try{
        my $qc_well = $c->model('Golgi')->retrieve_qc_template_well({ id => $well_id});

        my $fh_tmp = File::Temp->new() or die "Could not open temp file - $!";

        generate_genbank_for_qc_well($qc_well,$fh_tmp);

        # reopen filehandle as Seq::IO writer closes it
	    open (my $fh, "<", $fh_tmp->filename)
	        or die ("Could not open temp file ".$fh_tmp." for reading - $!");

	    my $filename = $qc_well->qc_template->name."_".$qc_well->name.".gbk";

        $c->res->content_type('text/plain');
        $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
        $c->res->body( do{ local $/ = undef; <$fh> } );
        close $fh;
    }
    catch{
    	$c->stash->{error_msg} = 'Error generating genbank file for qc template well: '.$_;
    };

    return;
}

__PACKAGE__->meta->make_immutable;

1;
