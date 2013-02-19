package LIMS2::Report::GenesToElectroporate;

use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use List::Util qw( max );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );
#TODO deal with single targeted

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

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

has gene_electroporate_list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_gene_electroporate_list {
    my $self = shift;

    my $arf = LIMS2::AlleleRequestFactory->new( model => $self->model, species => $self->species );

    my $project_rs;
    if ( $self->has_sponsor ) {
        $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );
    }
    else {
        $project_rs = $self->model->schema->resultset('Project')->search( {} );
    }

    my %wells;
    my @electroporate_list;
    while ( my $project = $project_rs->next ) {

=head
        my $ar = $arf->allele_request( decode_json( $project->allele_request ) );

        my %data;
        $data{gene_id}       = $ar->gene_id;
        $data{marker_symbol} = $self->model->retrieve_gene(
            { species => $self->species, search_term => $ar->gene_id } )->{gene_symbol};


        $data{first_allele_promoter_dna_wells}
            = valid_dna_wells( $ar, { type => 'first_allele_dna_wells', promoter => 1 } );
        $data{first_allele_promoterless_dna_wells}
            = valid_dna_wells( $ar, { type => 'first_allele_dna_wells', promoter => 0 } );
        $data{second_allele_promoter_dna_wells}
            = valid_dna_wells( $ar, { type => 'second_allele_dna_wells', promoter => 1 } );
        $data{second_allele_promoterless_dna_wells}
            = valid_dna_wells( $ar, { type => 'second_allele_dna_wells', promoter => 0 } );
=cut

        my %data;
        $data{gene_id}       = $project->gene_id;
        $data{marker_symbol} = $self->model->retrieve_gene(
            { species => $self->species, search_term => $project->gene_id } )->{gene_symbol};
            
        $data{first_allele_promoter_dna_wells}
            = $self->valid_dna_wells( $project, \%wells, { allele => 'first', promoter => 1 } );
        $data{first_allele_promoterless_dna_wells}
            = $self->valid_dna_wells( $project, \%wells, { allele => 'first', promoter => 0 } );
        $data{second_allele_promoter_dna_wells}
            = $self->valid_dna_wells( $project, \%wells, { allele => 'second', promoter => 1 } );
        $data{second_allele_promoterless_dna_wells}
            = $self->valid_dna_wells( $project, \%wells, { allele => 'second', promoter => 0 } );
            
        $data{fep_wells} = $self->electroporation_wells( $project, \%wells, 'first' );
        $data{sep_wells} = $self->electroporation_wells( $project, \%wells, 'second' );

        push @electroporate_list, \%data;
    }

    return \@electroporate_list;
}

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Genes To Electroporate ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Gene ID',
        'Marker Symbol',
        '1st Allele Promoter DNA Well',
        '1st Allele Promoterless DNA Well',
        '2nd Allele Promoter DNA Well',
        '2nd Allele Promoterless DNA Well',
        'FEP Well',
        'SEP Well',
    ];
};

override iterator => sub {
    my ($self) = @_;

    my $electroporate_list = $self->gene_electroporate_list;
    my @sorted_electroporate_list
        = sort { scalar( @{ $a->{fep_wells} } ) <=> scalar( @{ $b->{fep_wells} } ) }
        @{$electroporate_list};

    my $result = shift @sorted_electroporate_list;

    return Iterator::Simple::iter(
        sub {
            return unless $result;
            my @data = ( $result->{gene_id}, $result->{marker_symbol} );

            $self->print_wells( \@data, $result, 'first_allele_promoter_dna_wells');
            $self->print_wells( \@data, $result, 'first_allele_promoterless_dna_wells');
            $self->print_wells( \@data, $result, 'second_allele_promoter_dna_wells');
            $self->print_wells( \@data, $result, 'second_allele_promoterless_dna_wells');
            $self->print_electroporation_wells( \@data, $result, 'fep_wells');
            $self->print_electroporation_wells( \@data, $result, 'sep_wells');

            $result = shift @sorted_electroporate_list;
            return \@data;
        }
    );
};

=head
sub print_wells{
    my ( $self, $data, $result, $type ) = @_;

    push @{ $data }, join( " - ", map{ $_->plate->name . '[' . $_->name . ']' } @{ $result->{$type} } );
    return;
}
=cut
sub print_wells{
	my ( $self, $data, $result, $type ) = @_;
	
	push @{ $data }, join( " - ", map{ $_->dna_plate_name . '[' . $_->dna_well_name . ']' } 
	                       @{ $result->{$type} });
	return;
}

sub print_electroporation_wells{
    my ( $self, $data, $result, $type ) = @_;

    my @ep_data;
    my $prefix = $type eq 'fep_wells' ? 'ep'  :
                 $type eq 'sep_wells' ? 'sep' :
                 die "Unknown ep type: $type";
    
    for my $datum ( @{ $result->{$type} } ) {
        my $well_data = $datum->$prefix.'_plate_name' . '[' . $datum->$prefix.'_well_name' . ']';
        $well_data
            .= ' ('
            . $datum->dna_plate_name . '['
            . $datum->dna_well_name . '] )';

        push @ep_data, $well_data;
    }

    push @{ $data }, join( " - ", @ep_data );
    return;    
    
}
=head
sub print_electroporation_wells{
    my ( $self, $data, $result, $type ) = @_;

    my @ep_data;

    for my $datum ( @{ $result->{$type} } ) {
        my $well_data = $datum->{'well'}->plate->name . '[' . $datum->{'well'}->name . ']';
        $well_data
            .= ' ('
            . $datum->{'parent_dna_well'}->plate->name . '['
            . $datum->{'parent_dna_well'}->name . '] )';

        push @ep_data, $well_data;
    }

    push @{ $data }, join( " - ", @ep_data );
    return;
}
=cut

sub valid_dna_wells {
    my ( $self, $project, $wells, $params ) = @_;
    
    my @dna_wells;

    # Find vector wells for the project
    $self->vectors($project, $wells, $params->{allele});

    my $vectors = $params->{allele}.'_vectors';
    foreach my $well ($wells->{$vectors}){
    	next unless my $id = $well->dna_well_id;
    	
    	# CHECK: this is not the same as logic in orig code
    	next unless $well->dna_status_pass;
    	
    	# FIXME: should add dna_well_cassette/cassette_promoter to summaries
    	my $dna_well = $self->model->schema->resultset('Well')->find($id);
    	my $cassette = $dna_well->cassette;
    	
    	if ( $params->{promoter} ){
    		push @dna_wells, $well if $cassette->promoter;
    	}
    	else{
    		push @dna_wells, $well unless $cassette->promoter;
    	}
    }
    
=head    
    my $type = $params->{type};
    return unless $ar->can( $type );
    for my $well ( @{ $ar->$type } ) {
        next if exists $dna_wells{ $well->as_string };

        my $dna_status = $well->well_dna_status;
        if ( $dna_status ) {
            next unless $dna_status->pass;
            $dna_wells{ $well->as_string } = $well;
        }

        my $cassette = $well->cassette;

        if ( $params->{promoter} ) {
            $dna_wells{ $well->as_string } = $well
                if $cassette->promoter;
        }
        else {
            $dna_wells{ $well->as_string } = $well
                unless $cassette->promoter;
        }
    }
=cut

    return \@dna_wells;
}

sub electroporation_wells {	
	my ($self, $project, $wells, $allele) = @_;
	
	my @ep_wells;
	my $vectors = $allele.'_vectors';
	my $ep_well = $allele eq 'first'  ? 'ep_well_id'  :
	              $allele eq 'second' ? 'sep_well_id' :
	              die "Unknown allele type $allele";
	
	foreach my $well (@{ $wells->{$vectors} || [] }){
		push @ep_wells, $well if $well->$ep_well;
	}
	
	return \@ep_wells;
}
=head
sub electroporation_wells {
    my ( $ar, $type ) = @_;

    my %wells;
    return unless $ar->can( $type );
    for my $well ( @{ $ar->$type } ) {
        next if exists $wells{ $well->as_string };

        $wells{ $well->as_string }{ 'well' } = $well;
        $wells{ $well->as_string }{ 'parent_dna_well' } = _find_dna_parent_well( $well );

    }

    return [ values %wells ];
}
=cut

sub _find_dna_parent_well {
    my ( $ep_well ) = @_;

    my $it = $ep_well->ancestors->breadth_first_traversal($ep_well, 'in');
    while ( my $well = $it->next ) {
        return $well
            if $well->plate->type_id eq 'DNA';
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
