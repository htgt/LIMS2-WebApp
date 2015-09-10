package LIMS2::WebApp::Controller::User::CrisprPlateUpload;
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

sub crispr_plate_upload :Path( '/user/crispr_plate_upload' ) :Args(0){
    my ( $self, $c ) = @_;

}

