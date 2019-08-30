package LIMS2::WebApp::Controller::User::Miseq;
use Moose;
use namespace::autoclean;
use LIMS2::Model::Util::MiseqImport;
use Try::Tiny;
use JSON;

BEGIN { extends 'Catalyst::Controller' }

sub _check_params {
    my ( $request, %required ) = @_;
    foreach my $key ( keys %required ) {
        my $spec = $required{$key};
        if ( not ref $spec ) {
            $spec = { type => 'param', message => $spec };
        }
        my $type = $spec->{type};
        if ( not defined $request->$type($key) ) {
            die $spec->{message};
        }
    }
    return;
}

sub submit : Path('/user/miseq/submit') : Args(0) {
    my ( $self, $c ) = @_;

    try {
        foreach my $var (qw/PROCESS_PATH SCRIPTS_PATH STORAGE_PATH RAW_PATH/) {
            die "LIMS2_MISEQ_$var is not set"
              if not exists $ENV{"LIMS2_MISEQ_$var"};
        }

        _check_params(
            $c->request,
            'miseq_plate' => 
                'You must specify which MiSeq plate was sent',
            'walkup' =>
                'You must specify which MiSeq walkup contained the data',
            'run_data' => 
                'You must specify a Miseq plate and/or MiSeq manifest',
        );
        my $importer = LIMS2::Model::Util::MiseqImport->new;
        my $run_data = decode_json $c->request->param('run_data');

        my $data     = $importer->process(
            plate       => $c->request->param('miseq_plate'),
            walkup      => $c->request->param('walkup'),
            run_data    => $run_data,
        );
        while ( my ( $key, $value ) = each( %{$data} ) ) {
            $c->stash->{$key} = $value;
        }
    }
    catch {
        $c->stash->{error_msg} = $_;
    };

    return;
}

sub sequencing : Path('/user/miseq/sequencing') : Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;
    my $bs    = LIMS2::Model::Util::BaseSpace->new;
    my @plates =
      $c->model('Golgi')->schema->resultset('Plate')
      ->search( { type_id => 'MISEQ' }, { columns => [qw/id name/] }, );
    try {
        $c->stash->{plates} = [ sort { $b->id <=> $a->id } @plates ];
        $c->stash->{projects} =
          [ sort { $b->created cmp $a->created } $bs->projects ];
    }
    catch {
        $c->stash->{error_msg} = $_;
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;

