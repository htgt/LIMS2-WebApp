package LIMS2::Report::SponsorProgress;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SponsorProgress::VERSION = '0.103';
}
## use critic


use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use Readonly;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

extends qw( LIMS2::ReportGenerator );

Readonly my %REPORT_CATAGORIES => (
    genes => {
        name       => 'Targetted Genes',
        order      => 1,
    },
    vectors =>{
        name      => 'Vectors',
        order     => 2,
    },
    first_vectors => {
        name      => '1st Allele Vectors',
        order     => 3,
    },
    second_vectors => {
        name      => '2nd Allele Vectors',
        order     => 4,
    },
    dna => {
        name       => 'Valid DNA',
        order      => 5,
    },
    first_dna => {
        name       => '1st Allele Valid DNA',
        order      => 6,
    },
    second_dna => {
        name       => '2nd Allele Valid DNA',
        order      => 7,
    },
    ep => {
        name      => 'Electroporations',
        order     => 8,
    },
    first_ep => {
        name      => '1st Allele Electroporations',
        order     => 9,
    },
    second_ep => {
        name      => '2nd Allele Electroporations',
        order     => 10,
    },
    clones => {
        name       => 'Clones',
        order      => 11,
    },
    first_clones   => {
        name       => '1st Allele Accepted Clones',
        order      => 12,
    },
    second_clones => {
        name       => '2nd Allele Accepted Clones',
        order      => 13,
    },
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

has sponsors => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_sponsors {
    my $self = shift;

    my @sponsors = $self->model->schema->resultset('Sponsor')->search(
        { }, { order_by => { -asc => 'description' } }
    );

    return [ map{ $_->id } @sponsors ];
}

has sponsor_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data {
    my $self = shift;
    my %sponsor_data;

    my $project_rs = $self->model->schema->resultset('Project')->search( {} );

    while ( my $project = $project_rs->next ) {
        $self->_find_project_wells( $project, \%sponsor_data );
    }

    return \%sponsor_data;
}

sub _find_project_wells {
	my ( $self, $project, $sponsor_data ) = @_;

    my $sponsor = $project->sponsor_id;

    my %wells;

    DEBUG "finding wells for project ".$project->id;

    # We have to process the categories in order because, e.g. finding DNA
    # wells depends on vector wells having already been identified
    foreach my $name (sort { $REPORT_CATAGORIES{$a}->{order} <=> $REPORT_CATAGORIES{$b}->{order} }
                      (keys %REPORT_CATAGORIES) ) {
        $sponsor_data->{$name}{$sponsor}++
            if $self->$name($project,\%wells);
    }

    return;
}

sub genes{
	my ($self, $project, $wells) = @_;

    DEBUG "finding genes";

    # This just counts all projects that have associated gene IDs...
    return $project->gene_id ? 1 : 0;
}


sub dna{
	my ($self, $project, $wells, $allele) = @_;

	my $vector_category;
	if ($project->targeting_type eq "single_targeted"){
		$allele = 'first';
		$vector_category = 'vectors';
	}

	return 0 unless $allele;

    DEBUG "finding $allele allele DNA";

	$vector_category ||= $allele.'_vectors';

	# Find any DNA wells created from vector wells which have dna_status_pass
    foreach my $summary (@{ $wells->{$vector_category} || [] }){
    	return 1 if $summary->dna_status_pass;
    }

    return 0;
}

sub first_dna{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->dna($project, $wells, 'first');
}

sub second_dna{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->dna($project, $wells, 'second');
}

sub ep{
	my ($self, $project, $wells, $allele) = @_;

	my ($ep_well, $vector_category, $ep_category);
	if ($project->targeting_type eq "single_targeted"){
		$allele = 'first';
		$ep_well = 'ep_well_id';
		$vector_category = 'vectors';
		$ep_category = 'ep';
	}
	else{
		return 0 unless $allele;
		if($allele eq 'first'){
			$ep_well = 'ep_well_id';
			$vector_category = 'first_vectors';
			$ep_category = 'first_ep';
		}
		elsif($allele eq 'second'){
			$ep_well = 'sep_well_id';
			$vector_category = 'second_vectors';
			$ep_category = 'second_ep';
		}
	}

	DEBUG "finding $allele allele electroporations";

	# Find EP/SEP wells created from vector wells
	my @matching_rows;
    foreach my $summary (@{ $wells->{$vector_category} || [] }){
    	push @matching_rows, $summary if $summary->$ep_well;
    }

	# Store for subsequent queries
	$wells->{$ep_category} = \@matching_rows;

	return @matching_rows ? 1 : 0;
}

sub first_ep{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->ep($project, $wells, 'first');
}

sub second_ep{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->ep($project, $wells, 'second');
}

sub clones{
	my ($self, $project, $wells, $allele) = @_;

	my ($clone_accepted, $ep_category);
	if ($project->targeting_type eq "single_targeted"){
		$allele = 'first';
		$clone_accepted = 'ep_pick_well_accepted';
		$ep_category = 'ep';
	}
	else{
		return 0 unless $allele;
		if($allele eq 'first'){
			$clone_accepted = 'ep_pick_well_accepted';
			$ep_category = 'first_ep';
		}
		elsif($allele eq 'second'){
			$clone_accepted = 'sep_pick_well_accepted';
			$ep_category = 'second_ep';
		}
	}

    DEBUG "finding $allele allele clones";

	# Find EP_PICK/SEP_PICK wells created from EP/SEP wells	
	# which have is_accepted flag
	foreach my $summary (@{ $wells->{$ep_category} || [] }){
		return 1 if $summary->$clone_accepted;
	}

	return 0;
}

sub first_clones{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->clones($project, $wells, 'first');
}

sub second_clones{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->clones($project, $wells, 'second');
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();

    return 'Sponsor Progress Report ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Stage',
        @{ $self->sponsors }
    ];
};

override iterator => sub {
    my ($self) = @_;

    my @sponsor_data;

    for my $catagory ( sort { $REPORT_CATAGORIES{$a}->{order} <=> $REPORT_CATAGORIES{$b}->{order} }
        keys %REPORT_CATAGORIES )
    {
        my $data = $self->sponsor_data->{$catagory};
        $data->{catagory} = $catagory;
        push @sponsor_data, $data;
    }

    my $result = shift @sponsor_data;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = map{ $result->{$_} } @{ $self->sponsors };
            unshift @data, $REPORT_CATAGORIES{ $result->{catagory} }{name};

            $result = shift @sponsor_data;
            return \@data;
        }
    );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
