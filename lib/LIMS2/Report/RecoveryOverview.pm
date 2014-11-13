package LIMS2::Report::RecoveryOverview;

use Moose;
use MooseX::ClassAttribute;
use DateTime;
use JSON qw( decode_json );
use Readonly;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

extends qw( LIMS2::ReportGenerator );

has '+custom_template' => (
    default => 'user/report/recovery_overview.tt',
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has stage_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has crispr_stage_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_stage_data {
   my ($self) = @_;

   DEBUG "Building stage data";
   return {};
}

sub _build_crispr_stage_data {

}

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

Readonly my %STAGES => (
    crispr_ep_created => {
    	name       => 'Crispr EP Created',
    	field_name => 'crispr_ep_well_id',
    },
    ep_pick_created => {
    	name       => 'EP Pick Created',
    	field_name => 'ep_pick_well_id',
    },
    fp_created => {
    	name       => 'Freeze Plate Created',
    	field_name => 'fp_well_id',
    },
    piq_created => {
    	name       => 'PIQ Created',
    	field_name => 'piq_well_id',
    },
    piq_accepted => {
    	name       => 'PIQ Accepted',
    	field_name => 'piq_well_accepted',
    },
);

Readonly my %CRISPR_STAGES => (

);

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Recovery Overview ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [];
};

override iterator => sub {
    my ($self) = @_;

    DEBUG "getting iterator";

    my $result = $self->stage_data;

    return Iterator::Simple::iter([
        [qw(test1 test2)],
        [qw(test3 test4)]
    ]);
};

return 1;

