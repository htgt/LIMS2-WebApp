use strict;
use LIMS2::Model::Util::PrimerGenerator;
use Log::Log4perl qw(:easy);

BEGIN { Log::Log4perl->easy_init($INFO) };


my $generator = LIMS2::Model::Util::PrimerGenerator->new({
    plate_name => 'HG4',
    persist_file => 1,
    left_crispr_plate_name => 'HCL4',
    right_crispr_plate_name => 'HCR4',
    plate_well_names => ['A04'],
    species_name => 'Human',
});

=head
my $generator = LIMS2::Model::Util::PrimerGenerator->new({
    plate_name => 'MCA0001',
    plate_well_names => ['C01'],
    persist_file => 1,
    crispr_type => 'single',
    species_name => 'Mouse',
});
=cut

$generator->log->info("testing logger");
$generator->generate_crispr_primers();
