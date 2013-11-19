package LIMS2::ReportGenerator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::VERSION = '0.128';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use Iterator::Simple;
use JSON;
use Log::Log4perl qw( :easy );
use namespace::autoclean;

has name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has columns => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    init_arg   => undef,
    lazy_build => 1
);

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has cache_ttl => (
    is      => 'ro',
    isa     => 'Str',
    default => '22 hours'
);

has param_names => (
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    handles => { param_names => 'elements' },
    default => sub { [] }
);

sub _build_name {
    confess( "_build_name() must be implemented by a subclass" );
}

sub _build_columns {
    confess( "_build_columns() must be implemented by a subclass" );
}

sub iterator {
    confess( "iterator() must be implemented by a subclass" );
}

sub boolean_str {
    my ( $self, $bool ) = @_;

    if ( $bool ) {
        return 'yes';
    }
    else {
        return 'no';
    }
}

sub cached_report {
    my $self = shift;

    my @cached = $self->model->schema->resultset('CachedReport')->search(
        {
            report_class => ref $self,
            params       => JSON->new->utf8->canonical->encode( $self->params_hash ),
            expires      => { '>' => \'current_timestamp' }
        },
        {
            order_by => { -desc => 'expires' }
        }
    );

    my @complete = grep { $_->complete } @cached;
    if ( @complete ) {
        return $complete[0];
    }
    elsif ( @cached ) {
        return $cached[0];
    }

    return;
}

sub init_cached_report {
    my ( $self, $report_id ) = @_;

    my $cache_entry = $self->model->schema->resultset('CachedReport')->create(
        {
            id           => $report_id,
            report_class => ref $self,
            params       => JSON->new->utf8->canonical->encode( $self->params_hash ),
            expires      => \sprintf( 'current_timestamp + interval \'%s\'', $self->cache_ttl )
        }
    );

    return $cache_entry;
}

sub params_hash {
    my $self = shift;

    return { map { $_ => $self->$_ }  $self->param_names };
}

# Shared methods to identify and store vector wells that match
# the project specification
sub vectors{
	my ($self, $project, $wells, $allele) = @_;

	my $category;

    if ($allele){
    	$category = $allele.'_vectors';
    }
    elsif ($project->targeting_type eq 'single_targeted'){
    	$allele = 'first';
    	$category = 'vectors';
    }
    else{
    	return 0;
    }

    DEBUG "finding $allele allele vectors";

    # Find the cassette function specification for this allele
    my $project_allele = $project->project_alleles->find({ allele_type => $allele });
    return 0 unless $project_allele;
    my $function = $project_allele->cassette_function;

    # Find all final vectors matching project gene_id, mutation type and satisfying
    # the cassette function for this allele
    my @matching_rows;
    my $gene = $project->gene_id;
    my $design_types = $self->design_types_for($project_allele->mutation_type);

    # FIXME: should be filtering on species too
    my $where = {
        design_gene_id => $gene,
        final_pick_well_id => { '!=', undef },
        design_type => {-in => $design_types },
    };

    my $summary_rs = $self->model->schema->resultset('Summary')->search($where);

    while (my $summary = $summary_rs->next){
    	push @matching_rows, $summary if $summary->satisfies_cassette_function($function);
    }

    # Store matching rows for subsequent queries
    $wells->{$category} = \@matching_rows;

    return @matching_rows ? 1 : 0;
}

sub first_vectors{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->vectors($project, $wells, 'first');
}

sub second_vectors{
	my ($self, $project, $wells) = @_;

	return 0
	    unless $project->targeting_type eq "double_targeted";

	return $self->vectors($project, $wells, 'second');
}


sub design_types_for {
    my ( $self, $mutation_type ) = @_;

    if ( $mutation_type eq 'ko_first' ) {
        return [ 'conditional', 'artificial-intron', 'intron-replacement' ];
    }
    if ( $mutation_type eq 'deletion' or $mutation_type eq 'insertion' ){
        return [ $mutation_type ];
    }
    if ( $mutation_type eq 'cre_knock_in'){
        return [ 'conditional', 'artificial-intron', 'intron-replacement', 'deletion', 'insertion', 'cre-bac' ];
    }

    $self->model->throw( Implementation => "Unrecognized mutation type: $mutation_type" );

    return;
}
__PACKAGE__->meta->make_immutable();

1;

__END__

