package LIMS2::Report::GenesToElectroporate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::GenesToElectroporate::VERSION = '0.260';
}
## use critic


use Moose;
use DateTime;
use LIMS2::AlleleRequestFactory;
use JSON qw( decode_json );
use List::Util qw( max );
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use LIMS2::Model::Schema::Result::Well;

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
    if ( $self->has_sponsor && $self->sponsor ne 'All' ) {
        $project_rs = $self->model->schema->resultset('Project')->search( { sponsor_id => $self->sponsor } );
    }
    else {
        if ($self->species eq 'Mouse') {
            $project_rs = $self->model->schema->resultset('Project')->search(
                { sponsor_id => { -in => ['Core', 'Syboss', 'Pathogens'] }
            } );
        } else {
            $project_rs = $self->model->schema->resultset('Project')->search(
                { sponsor_id => { -in => ['All', 'Experimental Cancer Genetics', 'Mutation', 'Pathogen', 'Stem Cell Engineering', 'Transfacs'] }
            } );
        }
    }

    my @electroporate_list;

    while ( my $project = $project_rs->next ) {
    	my %wells;
        my %data;

        $data{gene_id} = $project->gene_id;

        # Temporarily shut down Human gene search while there is no Human gene index
        my $gene_symbol = '';

        if ($self->species eq 'Mouse') {

            $gene_symbol = $self->model->retrieve_gene({
                                    species => $self->species,
                                    search_term => $project->gene_id
                                })->{gene_symbol};
        }
        $data{marker_symbol} = $gene_symbol;

        # Find vector wells for the project
        $self->vectors($project, \%wells, 'first');
        $self->vectors($project, \%wells, 'second');

        # Then identify DNA and EP wells
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

    my $sponsor = $self->sponsor;
    if ($sponsor eq 'Cre Knockin') {
        return [
            'Gene ID',
            'Marker Symbol',
            'Promoter DNA Well',
            'Promoterless DNA Well',
            'FEP Well',
        ];
    } else {
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
    }
};

override iterator => sub {
    my ($self) = @_;

    my $electroporate_list = $self->gene_electroporate_list;
    my @sorted_electroporate_list
        = sort { scalar( @{ $a->{fep_wells} } ) <=> scalar( @{ $b->{fep_wells} } ) }
        @{$electroporate_list};

    my $result = shift @sorted_electroporate_list;

    my $sponsor = $self->sponsor;
    if ($sponsor eq 'Cre Knockin') {
        return Iterator::Simple::iter(
            sub {
                return unless $result;
                my @data = ( $result->{gene_id}, $result->{marker_symbol} );

                $self->print_wells( \@data, $result, 'first_allele_promoter_dna_wells');
                $self->print_wells( \@data, $result, 'first_allele_promoterless_dna_wells');
                $self->print_electroporation_wells( \@data, $result, 'fep_wells');

                $result = shift @sorted_electroporate_list;
                return \@data;
            }
        );
    } else {
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

    }
};

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

    my $plate = $prefix.'_plate_name';
    my $well = $prefix.'_well_name';

    for my $datum ( @{ $result->{$type} } ) {
        my $well_data = $datum->$plate . '[' . $datum->$well . ']';
        $well_data
            .= ' ('
            . $datum->dna_plate_name . '['
            . $datum->dna_well_name . '] )';

        push @ep_data, $well_data;
    }

    push @{ $data }, join( " - ", @ep_data );
    return;
}

sub valid_dna_wells {
    my ( $self, $project, $wells, $params ) = @_;

    my %dna_wells;

    # Find appropriate DNA wells derived from project's vector wells
    my $vectors = $params->{allele}.'_vectors';
    foreach my $well (@{ $wells->{$vectors} || [] }){
    	next unless my $id = $well->dna_well_id;
    	next if exists $dna_wells{$id};

    	next unless $well->dna_status_pass;

        # acs - 20_05_13 redmine 10335 - also check for vector final pick QC pass
        next unless $well->final_pick_qc_seq_pass;

    	if ( $params->{promoter} ){

            # acs - 20_05_13 redmine 10335 - use final_pick instead of final
            # $dna_wells{$id} = $well if $well->final_cassette_promoter;
    		$dna_wells{$id} = $well if $well->final_pick_cassette_promoter;
    	}
    	else{
            # acs - 20_05_13 redmine 10335 - use final_pick instead of final
            # $dna_wells{$id} = $well unless $well->final_cassette_promoter;
    		$dna_wells{$id} = $well unless $well->final_pick_cassette_promoter;
    	}
    }

    return [ values %dna_wells ];
}

sub electroporation_wells {
	my ($self, $project, $wells, $allele) = @_;

	my %ep_wells;

	my $vectors = $allele.'_vectors';
	my $ep_well = $allele eq 'first'  ? 'ep_well_id'  :
	              $allele eq 'second' ? 'sep_well_id' :
	              die "Unknown allele type $allele";

	# Find EP wells derived from project's DNA wells
	foreach my $well (@{ $wells->{$vectors} || [] }){
		next unless my $id = $well->$ep_well;
		next if exists $ep_wells{$id};
		$ep_wells{$id} = $well;
	}

	return [ values %ep_wells ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__
