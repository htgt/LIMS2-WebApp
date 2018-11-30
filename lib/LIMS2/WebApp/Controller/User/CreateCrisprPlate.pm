package LIMS2::WebApp::Controller::User::CreateCrisprPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CreateCrisprPlate::VERSION = '0.516';
}
## use critic

use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use Text::CSV;
use LIMS2::Model::Util::BacsForDesign qw( bacs_for_design );
use MooseX::Types::Path::Class;
use namespace::autoclean;
use Data::UUID;
use Path::Class;
use LIMS2::Util::QcPrimers;

BEGIN { extends 'Catalyst::Controller' };

with qw(
MooseX::Log::Log4perl
WebAppCommon::Crispr::SubmitInterface
);

sub create_crispr_plate :Path( '/user/create_crispr_plate' ) :Args(0){
    my ( $self, $c ) = @_;
    $c->log->info( 'Creating crispr plate: '  );
    my $req_crispr_plate = $c->req->param('datafile');
    my $req_plate_name = $c->req->param('plate_name');
    my $upload_plate_data = $c->request->upload('datafile');

    my @append_arr;
    my $append_rs = $c->model('Golgi')->schema->resultset('CrisprPlateAppendsType')->search({ id => { '!=', undef } });
    while (my $append = $append_rs->next) {
        push ( @append_arr, $append->{_column_data}->{id});
    }
    $c->stash(
        append_list => \@append_arr,
    );


    if ($req_crispr_plate){
        unless ($req_plate_name){
            $c->stash->{error_msg} = "Please enter a plate name";
            return;
        }
        try{
            build_crispr_plate_data($c, $upload_plate_data, $req_plate_name);
            unless($c->{crispr_plate_data}){
                return;
            }
            $c->model('Golgi')->create_plate( $c->{crispr_plate_data} );
            unless($c->stash->{error_msg}){
                $c->stash->{info_msg} = 'Successful crispr plate creation';
            }
        } catch {
            $c->stash->{error_msg} = "Error creating plate: " . $_;
        };
    }
    if ($req_plate_name && !$req_crispr_plate) {
        $c->stash->{error_msg} = "No csv file containing crispr plate data uploaded."
    }

    return;

}

sub build_crispr_plate_data {
    my ($c, $plate, $plate_name) = @_;
    $c->log->info( 'Building crispr plate data' );
    my @wells;

    my $fh;
    my $csv = Text::CSV->new();
    open $fh, "<:encoding(utf8)", $plate->tempname or die;
    @wells = extract_data($c, $csv, $fh, @wells);
    close $fh;
    if ($c->stash->{error_msg}) {
        return;
    }
    my $req_append = $c->req->param('append_type');

    $c->{crispr_plate_data} = (
        {
            name       => $plate_name,
            species    => $c->session->{selected_species},
            type       => 'CRISPR',
            appends    => $req_append,
            created_by => $c->user->{_user}->{_column_data}->{name},
            wells      => \@wells,
        }
    );

    return;
}

sub extract_data{
    my ($c, $csv_h, $file_h, @wells) = @_;
    $csv_h->column_names( @{ $csv_h->getline( $file_h ) } );

    my @columns_array = $csv_h->column_names;
    my %columns = map { $_ => 1 } @columns_array;

    unless (exists($columns{'well_name'}) && exists($columns{'crispr_id'})){
        $c->stash->{error_msg} = 'Invalid file. The file must be a csv containing the headers "well_name" and "crispr_id".';
        return;
    }
    while ( my $data = $csv_h->getline_hr( $file_h ) ) {
        $c->log->debug( 'Process well data for: ' . $data->{well_name} );
        try{
            my $well_data = _build_well_data($c, $data);
            if ($well_data){
                push @wells, $well_data;
            }
        }
        catch {
            $c->stash->{error_msg} = ('Error creating well data: ' . $_ );
        };
    }
    return @wells;
}

sub _build_well_data {
    my ( $c, $data ) = @_;
    my $crispr;
    my $wge = $c->req->param('wge');

    try{
        if($wge){
            $crispr = $c->model('Golgi')->retrieve_crispr( { wge_crispr_id => $data->{crispr_id} } );
        }
        else{
            $crispr = $c->model('Golgi')->retrieve_crispr( { id => $data->{crispr_id} } );
        }
    };

    unless ($crispr){
        $c->stash->{error_msg} = "Error retrieving crispr " . $data->{crispr_id} . ": Crispr entity not found.";
        return;
    }

    my %well_data;
    $well_data{well_name}    = $data->{well_name};
    $well_data{crispr_id}    = $crispr->id;
    $well_data{process_type} = 'create_crispr';

    return \%well_data;
}

__PACKAGE__->meta->make_immutable;

1;

