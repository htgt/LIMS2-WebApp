package LIMS2::Report::DesignVectors;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DesignVectors::VERSION = '0.396';
}
## use critic


use Moose;

use DateTime;
use JSON qw( decode_json );
use List::Util qw( max );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw(:easy);
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

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

has plate_type => (
    is        => 'ro',
    isa       => 'Str',
);

has promoter_status => (
    is        => 'ro',
    isa       => 'Str',
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor', 'plate_type', 'promoter_status'] }
);

has design_vectors_list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_design_vectors_list {
    my $self = shift;

    my $project_rs;
    if ( $self->has_sponsor ) {
        $project_rs = $self->model->schema->resultset('Project')->search( {
            'project_sponsors.sponsor_id' => $self->sponsor
        },
        {
            join => 'project_sponsors',
        } );
    }
    else {
        $project_rs = $self->model->schema->resultset('Project')->search( {} );
    }

    my %vector_list_by_design;
    while ( my $project = $project_rs->next ) {
        my %wells;

        # Find vector wells for the project
        $self->vectors($project, \%wells, 'first');
        $self->vectors($project, \%wells, 'second');

        $self->classify_design_vectors($wells{first_vectors},'first', \%vector_list_by_design, $project);
        $self->classify_design_vectors($wells{second_vectors},'second', \%vector_list_by_design, $project);
    }

    return [values %vector_list_by_design];
}

sub classify_design_vectors{
	my ($self, $vectors, $type, $list, $project) = @_;

	my $by_design = _key_by_design_id($vectors);
    my $project_id = $project->id;

    foreach my $design_id (keys %{ $by_design }){
    	my $key = $design_id."_$project_id";
    	$list->{$key} ||= {};
    	my $data = $list->{$key};
    	$data->{sponsor} ||= $project->sponsor_id;
        $data->{design_id} ||= $design_id;
        $data->{project_id} ||= $project_id;
        $data->{gene_id} ||= $by_design->{$design_id}->[0]->design_gene_id;
        $data->{symbol} ||= $by_design->{$design_id}->[0]->design_gene_symbol;
        $data->{$type} = $by_design->{$design_id};
    }
    return;
}

sub _key_by_design_id{
	my ($summaries) = @_;

	my %by_design;
	foreach my $summary (@{ $summaries }){
		my $id = $summary->design_id;
		$by_design{$id} = [] unless exists $by_design{$id};
		push @{ $by_design{$id} }, $summary;
	}
	return \%by_design;
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';

    if($self->promoter_status){
    	$append .= $self->promoter_status.' ';
    }

    if($self->plate_type){
    	$append .= $self->plate_type.' ';
    }

    $append .= $dt->ymd;

    return 'Design Vectors ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Sponsor',
        'Project ID',
        'Gene ID',
        'Gene Symbol',
        'Design ID',
        'First Vector Wells Count',
        'First Vector Wells Accepted Count',
        'First Vector Wells List',
        'Second Vector Wells Count',
        'Second Vector Wells Accepted Count',
        'Second Vector Wells List',
    ];
};

override iterator => sub {
    my ($self) = @_;

    my @list = @{ $self->design_vectors_list };
    @list = sort { $a->{symbol} cmp $b->{symbol} } @list;

    my $result = shift @list;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = ( $result->{sponsor}, $result->{project_id}, $result->{gene_id}, $result->{symbol}, $result->{design_id} );

            push @data, $self->_counts_and_list($result->{first});
            push @data, $self->_counts_and_list($result->{second});

            $result = shift @list;
            return \@data;
        }
    );
};

sub _counts_and_list{
	my ($self, $summaries) = @_;

	my @wells = map { $self->_display_well_name($_) } @{ $summaries };
	my @unique = uniq @wells;
	my $list = join " - ", sort @unique;

	# Count the accepted wells
	my $accepted = grep { $_ =~ /\*/ } @unique;

	return (scalar @unique, $accepted, $list);
}

sub _display_well_name{
	my ($self, $summary) = @_;

    my @names;

	# Filter by promoter status if specified
	if ($self->promoter_status eq "promoter"){
		return @names unless $summary->final_pick_cassette_promoter;
	}
	elsif($self->promoter_status eq "promoterless"){
		return @names if $summary->final_pick_cassette_promoter;
	}

	# FIXME: Filter by NEO and BSD status.. this info first needs adding to cassette
	# table and then summaries table

	# Report only requested plate type, or both if not specified
	my @types;
	if ($self->plate_type){
		@types = $self->plate_type;
	}
	else{
		@types = qw(final final_pick);
	}

	foreach my $plate_type (@types){
		my ($plate, $well, $accepted) = map { lc($plate_type)."_".$_ } qw(plate_name well_name well_accepted);
        next unless $summary->$well;
	    my $name = $summary->$plate . '[' . $summary->$well . ']';
	    if($summary->$accepted){
	        $name.="*";
	    }
	    push @names, $name;
	}
	DEBUG "Names: @names";
	return @names;
}
__PACKAGE__->meta->make_immutable;

1;

__END__
