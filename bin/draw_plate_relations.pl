#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Log::Log4perl qw( :easy );
use GraphViz2;

use LIMS2::Model::Util::DrawPlateGraph qw(draw_plate_graph);

Log::Log4perl->easy_init($DEBUG);

draw_plate_graph($ARGV[0]);
