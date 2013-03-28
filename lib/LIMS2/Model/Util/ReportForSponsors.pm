package LIMS2::Model::Util::ReportForSponsors;

use strict;
use warnings FATAL => 'all';

use Moose;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use DateTime;
use Readonly;

Log::Log4perl->easy_init($DEBUG);

# Rows on report view
Readonly my @SINGLE_TARGETED_REPORT_CATEGORIES => (
    'Targeted Genes',
    'Vectors',
    'Valid DNA',
);

Readonly my @DOUBLE_TARGETED_REPORT_CATEGORIES => (
    'Targeted Genes',
    'Vectors',
    'Neo Vectors',
    'Blast Vectors',
    'Valid DNA',
    'Neo Valid DNA',
    'Blast Valid DNA',
);

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
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

has sponsor_data_single => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data_single {
    my $self = shift;
    my %sponsor_data_single;

	my @sponsor_ids = @{ $self->sponsors };

	foreach my $sponsor_id ( @sponsor_ids ) {
		DEBUG "single data sponsor id = ".$sponsor_id;
		$self->_build_sponsor_column_data_single_targeted( $sponsor_id, \%sponsor_data_single );
    }

    return \%sponsor_data_single;
}

has sponsor_data_double => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_sponsor_data_double {
    my $self = shift;
	my %sponsor_data_double;

	my @sponsor_ids = @{ $self->sponsors };

	foreach my $sponsor_id ( @sponsor_ids ) {
		DEBUG "double data sponsor id = ".$sponsor_id;
		$self->_build_sponsor_column_data_double_targeted( $sponsor_id, \%sponsor_data_double );
    }

    return \%sponsor_data_double;
}


sub _build_sponsor_column_data_single_targeted {
	my ( $self, $sponsor_id, $sponsor_data_single ) = @_;

	my $targeting_type = 'single_targeted';

	DEBUG "fetching column data for single-targeted projects ";

	$sponsor_data_single->{'Targeted Genes'}{$sponsor_id} = $self->genes( $sponsor_id, $targeting_type );

	# only continue if targeted genes found
	$sponsor_data_single->{'Vectors'}{$sponsor_id} = $self->vectors( $sponsor_id, $targeting_type );
	
	# only continue if vectors found
	$sponsor_data_single->{'Valid DNA'}{$sponsor_id} = $self->dna( $sponsor_id, $targeting_type );

}

sub _build_sponsor_column_data_double_targeted {
	my ( $self, $sponsor_id, $sponsor_data_double ) = @_;

	my $targeting_type = 'double_targeted';

	DEBUG "fetching column data for double-targeted projects ";

	$sponsor_data_double->{'Targeted Genes'}{$sponsor_id} = $self->genes( $sponsor_id, $targeting_type );

	# only continue if targeted genes found
    $sponsor_data_double->{'Vectors'}{$sponsor_id} = $self->vectors( $sponsor_id, $targeting_type );

	# only continue if vectors found
	$sponsor_data_double->{'Neo Vectors'}{$sponsor_id} = $self->neo_vectors( $sponsor_id, $targeting_type );
	$sponsor_data_double->{'Blast Vectors'}{$sponsor_id} = $self->blast_vectors( $sponsor_id, $targeting_type);

	# only continue if vectors found
    $sponsor_data_double->{'Valid DNA'}{$sponsor_id} = $self->dna( $sponsor_id, $targeting_type );

    # only continue if DNA found
	$sponsor_data_double->{'Neo Valid DNA'}{$sponsor_id} = $self->neo_dna( $sponsor_id, $targeting_type );
	$sponsor_data_double->{'Blast Valid DNA'}{$sponsor_id} = $self->blast_dna( $sponsor_id, $targeting_type );

}

# Generate front page report matrix
sub generate_top_level_report_for_sponsors {
	my $self = shift;	

    # filled from Sponsors table
	my $columns = $self->build_columns;

    # single- and double-targeted data filled by counting from DB
	my $st_data = $self->sponsor_data_single;
    my $dt_data = $self->sponsor_data_double;

	my $title = $self->build_name;

	my $st_rows = \@SINGLE_TARGETED_REPORT_CATEGORIES;
    my $dt_rows = \@DOUBLE_TARGETED_REPORT_CATEGORIES;

	my %return_params = (
		report_id => 'SponsRep',
        title     => $title,
        columns   => $columns,
		st_rows   => $st_rows,
		dt_rows   => $dt_rows,
        st_data   => $st_data,
        dt_data   => $dt_data,
	);

	return \%return_params;
}

# Set up SQL query to count targeted genes for sponsor id
sub create_sql_count_targeted_gene_projects_for_sponsor {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

	DEBUG "building query with sponsor_id = ".$sponsor_id." and targeting_type = ".$targeting_type;

my $sql_query =  <<"SQL_END";
SELECT COUNT(sponsor_id) 
FROM projects 
WHERE sponsor_id = '$sponsor_id'
AND targeting_type = '$targeting_type'; 
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of vectors for single-targeted projects e.g. Cre Knockin
sub create_sql_count_vectors_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT count(distinct(s.design_gene_id)) FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON s.final_cassette_name = c.name
 WHERE p.sponsor_id = '$sponsor_id'
 AND c.cre = 't'
 AND s.final_well_accepted = 't'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of vectors for double-targeted projects e.g. Syboss
sub create_sql_count_vectors_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type ) = @_;
	
my $sql_query =  <<"SQL_END";
SELECT COUNT(distinct(s.design_gene_id)) FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON s.final_pick_cassette_name = c.name
 WHERE p.sponsor_id = '$sponsor_id'
 AND c.cre = 'f'
 AND s.final_pick_well_accepted = 't'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Set up SQL query to count vectors which contain specific resistance 
# cassettes for double-targeted projects e.g. neoR cassette Syboss
sub create_sql_count_resistance_vectors_for_double_targeted_sponsor_project {
    my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
SELECT count(distinct(s.design_gene_id)) FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON c.name = s.final_pick_cassette_name
 WHERE p.sponsor_id = '$sponsor_id'
 AND s.final_pick_well_accepted = 't'
 AND c.cre = 'f'
 AND c.resistance = '$resistance'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted DNA wells for single-targeted projects e.g. Cre Knockin
sub create_sql_count_DNA_for_single_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT count(distinct(s.design_gene_id))
 FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON c.name = s.final_cassette_name
 WHERE p.sponsor_id = '$sponsor_id'
 AND c.cre = 't'
 AND s.dna_well_id > 0
 AND s.dna_status_pass = 't'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted DNA wells for double-targeted projects e.g. Syboss
sub create_sql_count_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type ) = @_;

my $sql_query =  <<"SQL_END";
SELECT count(distinct(s.design_gene_id))
 FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON c.name = s.final_pick_cassette_name
 WHERE p.sponsor_id = '$sponsor_id'
 AND c.cre = 'f'
 AND s.dna_well_id > 0
 AND s.dna_status_pass = 't'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Set up SQL query to count number of accepted resistance cassette DNA wells
# for double-targeted projects e.g. Syboss
sub create_sql_count_resistance_DNA_for_double_targeted_sponsor_project {
	my ( $self, $sponsor_id, $targeting_type, $resistance ) = @_;

my $sql_query =  <<"SQL_END";
SELECT count(distinct(s.design_gene_id))
 FROM summaries s
 LEFT JOIN projects p ON p.gene_id = s.design_gene_id
 LEFT JOIN cassettes c ON c.name = s.final_pick_cassette_name
 WHERE p.sponsor_id = '$sponsor_id'
 AND c.cre = 'f'
 AND s.dna_well_id > 0
 AND s.dna_status_pass = 't'
 AND c.resistance = '$resistance'
 AND p.targeting_type = '$targeting_type'
SQL_END

	return $sql_query;
}

# Generic method to run SQL
sub run_query {
   my ( $self, $sql_query ) = @_;

   my $count = 0;

   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         my @ret = $sth->fetchrow_array;
		 $count = $ret[0]; 
      }
   );

	return $count;
}

sub genes{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding targeted genes for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query = $self->create_sql_count_targeted_gene_projects_for_sponsor( $sponsor_id, $targeting_type );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub vectors{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $sql_query;

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_vectors_for_single_targeted_sponsor_project( $sponsor_id, $targeting_type );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_vectors_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub neo_vectors{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'neoR'; 

	my $sql_query = $self->create_sql_count_resistance_vectors_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub blast_vectors{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding blastR vectors for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

	my $resistance = 'blastR';

	my $sql_query = $self->create_sql_count_resistance_vectors_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub dna{
	my ( $self, $sponsor_id, $targeting_type ) = @_;
    
    DEBUG "finding dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $sql_query;

	if( $targeting_type eq 'single_targeted' ) {
       $sql_query = $self->create_sql_count_DNA_for_single_targeted_sponsor_project( $sponsor_id, $targeting_type );
	}
	elsif ( $targeting_type eq 'double_targeted' ) {
       $sql_query = $self->create_sql_count_DNA_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type );
	}
    else {
       return 0;
    } 

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub neo_dna{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'neoR'; 

	my $sql_query = $self->create_sql_count_resistance_DNA_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub blast_dna{
	my ( $self, $sponsor_id, $targeting_type ) = @_;

    DEBUG "finding neoR dna for sponsor id = ".$sponsor_id." and targeting_type = ".$targeting_type;

	my $count = 0;

    my $resistance = 'blastR'; 

	my $sql_query = $self->create_sql_count_resistance_DNA_for_double_targeted_sponsor_project( $sponsor_id, $targeting_type, $resistance );

	DEBUG "sql query = ".$sql_query;

	$count = $self->run_query( $sql_query );

    return $count;
}

sub build_name {
    my $self = shift;

    my $dt = DateTime->now();

    return 'Sponsor Progress Report ' . $dt->ymd;
};

sub build_columns {
    my $self = shift;

    return [
        'Stage',
        @{ $self->sponsors }
    ];
};

1;