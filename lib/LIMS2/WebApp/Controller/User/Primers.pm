package LIMS2::WebApp::Controller::User::Primers;

use Moose;
use namespace::autoclean;
use TryCatch;
use JSON;

BEGIN { extends 'Catalyst::Controller' };

# Returns JSON so this can be used in ajax request
sub toggle_genotyping_primer_validation_state : Path( '/user/toggle_genotyping_primer_validation_state' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_id = $c->request->param('design_id');
    my $primer_type = $c->request->param('primer_type');

    my $primer = $c->model('Golgi')->schema->resultset('GenotypingPrimer')->find({
            design_id => $design_id,
            genotyping_primer_type_id => $primer_type,
            is_rejected => [ 0, undef ],
    	});

    if($primer){
        my $orig_state = ( $primer->is_validated ? 1 : 0 );
        my $new_state = ( !$orig_state ? 1 : 0 );
        $c->log->debug("Changing genotyping primer validation state from $orig_state to $new_state");
        $primer->update({ is_validated => $new_state });

        $c->stash->{json_data} = { success => 1, is_validated => $primer->is_validated };
    }
    else{
    	$c->stash->{json_data} = { error => 'Primer not found' };
    }


    $c->forward('View::JSON');
}

# Returns JSON so this can be used in ajax request
sub toggle_crispr_primer_validation_state : Path( '/user/toggle_crispr_primer_validation_state' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $crispr_id = $c->request->param('crispr_id');
    my $crispr_pair_id = $c->request->param('crispr_pair_id');
    my $primer_type = $c->request->param('primer_type');

    my $search = {
    	primer_name => $primer_type,
        is_rejected => [ 0, undef ],
    };

    if($crispr_id){
    	$search->{crispr_id} = $crispr_id;
    }

    if($crispr_pair_id){
    	$search->{crispr_pair_id} = $crispr_pair_id;
    }

    my $primer = $c->model('Golgi')->schema->resultset('CrisprPrimer')->find($search);

    if($primer){
        my $orig_state = ( $primer->is_validated ? 1 : 0 );
        my $new_state = ( !$orig_state ? 1 : 0 );
        $c->log->debug("Changing crispr primer validation state from $orig_state to $new_state");
        $primer->update({ is_validated => $new_state });

        $c->stash->{json_data} = { success => 1, is_validated => $primer->is_validated };
    }
    else{
    	$c->stash->{json_data} = { error => 'Primer not found' };
    }


    $c->forward('View::JSON');
}

1;
