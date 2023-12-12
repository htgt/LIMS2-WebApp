#!/usr/bin/env perl

=head

Add the classification for the clones in a miseq-well-experiment.

=cut

use strict;
use warnings;
use feature qw(say);

use LIMS2::Model::Util::Miseq qw/ classify_reads /;

classify_reads();
