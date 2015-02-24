package LIMS2::WebApp::Controller::User::Primers;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Primers::VERSION = '0.291';
}
## use critic


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
    return;
}

# Returns JSON so this can be used in ajax request
sub toggle_crispr_primer_validation_state : Path( '/user/toggle_crispr_primer_validation_state' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $primer_type = $c->request->param('primer_type');

    my $search = {
    	primer_name => $primer_type,
        is_rejected => [ 0, undef ],
    };

    my $crispr_key = $c->request->param('crispr_key');
    my ($id,$type) = ($crispr_key =~ / (\d*) \s* \( (\w*) \) /ixms);

    unless ($id and $type){
    	$c->stash->{json_data} = { error => "Could not identify crispr ID and type in string $crispr_key" };
        $c->forward('View::JSON');
        return;
    }

    if($type eq "crispr"){
    	$search->{crispr_id} = $id;
    }
    elsif($type eq "crispr_pair"){
    	$search->{crispr_pair_id} = $id;
    }
    elsif($type eq "crispr_group"){
        $search->{crispr_group_id} = $id;
    }
    else{
        $c->stash->{json_data} = { error => "Crispr type \"$type\" not recognised" };
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
    return;
}

1;
