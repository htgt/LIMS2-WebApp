#!/usr/bin/perl
use strict;
use warnings;
use LIMS2::WebApp::Controller::User::Miseq;
use LIMS2::Context;
use Data::Dumper;

my $ctx = LIMS2::Context->new(
    plate       => 'Miseq_029',
    walkup      => 77599566,
    spreadsheet => '/nfs/users/nfs_j/jr27/Miseq_029.csv',
);
my $ctrl = LIMS2::WebApp::Controller::User::Miseq->new;
$ctrl->process($ctx);
print Dumper($ctx->stash);

