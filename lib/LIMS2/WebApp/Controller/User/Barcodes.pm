package LIMS2::WebApp::Controller::User::Barcodes;
use Moose;
use TryCatch;
use Data::Dump 'pp';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub generate_picklist : Path( '/user/generate_picklist' ) : Args(0){
	# Enter list of gene symbols
	# find all FP wells for it which are currently "in_freezer"
	# Provide as printable list contining plate/well position, barcodes, parent EPDs
	# blank columns for "to pick"/"picked"
}
1;