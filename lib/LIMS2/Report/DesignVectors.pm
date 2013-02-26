package LIMS2::Report::DesignVectors;

use Moose;
use MooseX::UndefTolerant;

use DateTime;
use JSON qw( decode_json );
use List::Util qw( max );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw(:easy);
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

Log::Log4perl->easy_init($DEBUG);

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
    predicate => 'has_plate_type',
);

has promoter_status => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_promoter_status',
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor', 'plate_type', 'promoter_status' ] }
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
        $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );
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

        $self->classify_design_vectors($wells{first_vectors},'first', \%vector_list_by_design, $project->id);
        $self->classify_design_vectors($wells{second_vectors},'second', \%vector_list_by_design, $project->id);
    }

    return [values %vector_list_by_design];
}

sub classify_design_vectors{
	my ($self, $vectors, $type, $list, $project) = @_;
	
	my $by_design = _key_by_design_id($vectors);
    
    foreach my $design_id (keys %{ $by_design }){
    	my $key = $design_id."_$project";
    	$list->{$key} ||= {};
    	my $data = $list->{$key};
        $data->{design_id} ||= $design_id;
        $data->{project_id} ||= $project;
        $data->{gene_id} ||= $by_design->{$design_id}->[0]->design_gene_id;
        $data->{$type.'_promoter'} = [ grep { $_->final_cassette_promoter == 1 } @{ $by_design->{$design_id} }];
        $data->{$type.'_promoterless'} = [ grep { $_->final_cassette_promoter == 0 } @{ $by_design->{$design_id} }];	
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
    $append .= $dt->ymd;

    return 'Design Vectors ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Project ID',
        'Gene ID',
        'Design ID',
        'First Promoter Vetcor Wells',
        'First Promoterless Vector Wells',
        'Second Promoter Vetcor Wells',
        'Second Promoterless Vector Wells',
    ];
};

override iterator => sub {
    my ($self) = @_;

    my @list = @{ $self->design_vectors_list };

    my $result = shift @list;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = ( $result->{project_id}, $result->{gene_id}, $result->{design_id} );
            
            push @data, $self->_print_wells($result->{first_promoter});
            push @data, $self->_print_wells($result->{first_promoterless});
            push @data, $self->_print_wells($result->{second_promoter});
            push @data, $self->_print_wells($result->{second_promoterless});
            
            $result = shift @list;
            return \@data;
        }
    );
};

sub _print_wells{
	my ($self, $summaries) = @_;

	my @wells = map { $self->_display_well_name($_) } @{ $summaries };
	my @unique = uniq @wells;
	my $list = join " - ", sort @unique;
	return $list;
}

sub _display_well_name{
	my ($self, $summary) = @_;
	
	my @types;
	if ($self->has_plate_type){
		@types = $self->plate_type;
	}
	else{
		@types = qw(final final_pick);
	}

	my @names;
	foreach my $plate_type (@types){
		my ($plate, $well, $accepted) = map { lc($plate_type)."_".$_ } qw(plate_name well_name well_accepted);
        next unless $summary->$well;
	    my $name = $summary->$plate . '[' . $summary->$well . ']';
	    $name.="*" if $summary->$accepted;
	    push @names, $name;
	}
	DEBUG "Names: @names";
	return @names;
}
__PACKAGE__->meta->make_immutable;

1;

__END__
