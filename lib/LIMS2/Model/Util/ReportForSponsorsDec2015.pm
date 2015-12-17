package LIMS2::Model::Util::ReportForSponsorsDec2015;

use Moose;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);
use LIMS2::Model::Util::DesignTargets qw( design_target_report_for_genes );
use LIMS2::Model::Constants qw( %DEFAULT_SPECIES_BUILD );

use List::Util qw(sum);
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;
use DateTime;
use Readonly;
use Try::Tiny;                              # Exception handling
use Data::Dumper;
use Text::CSV;
use Regexp::Assemble;

extends qw( LIMS2::ReportGenerator );

with qw( MooseX::Log::Log4perl );

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

has species => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has targeting_type => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has report_config => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

###########################################
#
# All subsequent attributes can be set from
# the report_config file when it is parsed
# in the BUILD method
#
############################################

# FIXME: think this has something to do with display - check
# (SponsSubReport is the other possible value)
has report_id => (
    is        => 'rw',
    isa       => 'Str',
    default   => 'SponsRep',
);

# Default is to display named categories as column headers
# and item list as rows but this can be changed in config
has categories_as_columns => (
    is         => 'rw',
    isa        => 'Bool',
    default    => 1,
);

# List of categories to report, e.g. 'Genes', 'Vectors Constructed'
# Will use simple list of strings and assume they are unique
# If this is not the case will change this to list of hashrefs containing
# display_name (to show in html) and unique_name (to refer to rules and queries)
has categories => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 0,
);

# Name for the types of category reported, e.g. 'Stage'
has category_name => (
    is         => 'rw',
    isa        => 'Str',
    required   => 0,
    default    => 'Category',
);

# List of items to report on e.g. list of sponsors, list of genes
has items => (
    is         => 'rw',
    isa        => 'ArrayRef',
    required   => 0,
);

# Hash of named sql queries which can be run for some or all categories
has base_sql_queries => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of sql to add to base sql based on category/item/species/targeting_type
# FIXME: not sure how to structure this, perhaps as regex dispatch
has sql_query_modifiers => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of named subroutines to be run for some or all categories
has base_methods => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of additional functions to run on output of base_method based on category/item/species/targeting_type
# FIXME: not sure how to structure this, perhaps as regex dispatch
has method_modifiers => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of base and modifier sql for each category
has category_sql => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of functions by category which will output styling params for given values
has category_styling_rules => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

sub BUILD {
    # Parse the report config and set object attributes accordingly
    my $self = shift;

    my ($settings, $rules) = $self->_parse_config_file();

}

sub _parse_config_file{
    my $self = shift;
    open my $fh, "<", $self->report_config or die $!;
    my $csv = Text::CSV->new ({ binary => 1, eol => $/, empty_is_undef => 1 });

    my $settings = {};
    my $rules = {};
    my @categories = ();

    while (my $row = $csv->getline($fh)) {
        if($row->[0] eq '!RULES'){
            my ($first_col, @headings) = @{ $csv->getline($fh) };

            $first_col eq 'Category'
                or die "First column of !RULES section must contain Category, not $first_col";

            while(my $rule_row = $csv->getline($fh)){
                # Store categories in array at this stage as the ordering
                # is lost once they are parsed into the rules hash
                push @categories, $rule_row->[0];
                $self->_parse_rules_row($rules, $rule_row, \@headings);
            }
        }
        else{
            $self->_parse_settings_row($settings, $row);
        }
    }

    # Set category list in correct order for display
    $self->categories(\@categories);

    # Apply any roles from config to bring in report type specific methods
    # roles should be supplied as a comma separated list
    if(my $roles_string = $settings->{roles}){
        my @roles = split /\s*,\s*/, $roles_string;
        apply_all_roles($self, @roles);
        # Now we are ready to process the settings and rules
    }

    DEBUG "Settings: ".Dumper($settings);
    $self->_process_settings($settings);

    DEBUG "Rules: ".Dumper($rules);
    $self->_process_rules($rules);

    return ($settings, $rules);
}

sub _parse_settings_row{
    my ($self, $settings, $row) = @_;

    my @values = @$row;

    # Lots of sanity checking
    if(scalar @values > 2){
        if(grep { defined $_ } @values[2..$#values] ){
            die "Error parsing config: more than 2 columns in settings at line $.";
        }
    }
    my ($key,$value) = @$row;
    if(defined $value){
        if(! defined $key){
            die "Error parsing config: Settings value $value provided with no key on line $."
        }
        if(exists $settings->{$key}){
            die "Error parsing config: Settings key $key is a duplicate on line $.";
        }

        # Looks ok so far so store the setting
        $settings->{$key} = $value;
    }

    return;
}

my $SETTINGS_DISPATCH = {
    'category_name'         => sub { my ($self,$value) = @_; $self->category_name($value) },
    'report_id'             => sub { my ($self,$value) = @_; $self->report_id($value) },
    'categories_as_columns' => sub { my ($self,$value) = @_; $self->categories_as_columns($value) },
    'items:SQL'             => sub { my ($self,$value) = @_; $self->items( $self->run_items_sql($value) ) },
    'items:PERL'            => sub { my ($self,$value) = @_; $self->items( $self->execute_perl($value) ) },
    'base:SQL:(.*)'         => sub { my ($self,$value,$name) = @_; $self->base_sql_queries->{$name} = $value; },
    'base:PERL:(.*)'        => sub { my ($self,$value,$name) = @_; $self->base_methods->{$name} = $value; },
    'modifier:SQL:(.*)'     => sub { my ($self,$value,$name) = @_; $self->sql_query_modifiers->{$name} = $value; },
    'modifier:PERL:(.*)'    => sub { my ($self,$value,$name) = @_; $self->method_modifiers->{$name} = $value; },
};

sub _process_settings{
    my ($self, $settings) = @_;

    my $ra = Regexp::Assemble->new( track => 1 )->add( keys %$SETTINGS_DISPATCH );

    while (my ($key,$value) = each %$settings){
        if( $ra->match($key) ){
            my $matched = $ra->matched;
            my ($name) = $ra->capture;
            $SETTINGS_DISPATCH->{$matched}->($self,$value,$name);
        }
    }

    return;
}

sub _parse_rules_row{
    my ($self, $rules, $rule_row, $headings_ref) = @_;

    my @headings = @$headings_ref;

    my ($category, @rules_list) = @{ $rule_row };
    foreach my $index (0..$#rules_list){
        my $rule = $rules_list[$index];

        # Rules can be blank - do nothing
        next unless defined $rule;

        # Store non-blank rule
        my $heading = $headings[$index];

        defined $heading or die "Rule $rule provided with no heading at line $.";

        $rules->{$category}{$heading} = $rule;
    }
    return;
}

my $RULES_DISPATCH = {
    'category_base:SQL'     => sub { my ($self,$cat,$val) = @_; $self->set_base_sql_for_category($cat,$val) },
    'category_modifier:SQL' => sub { my ($self,$cat,$val) = @_; $self->set_modifier_sql_for_category($cat,$val) },
    'condition:(.*)'        => sub { my ($self,$cat,$val,$condition) = @_; DEBUG "Set conditional modifier for category" },
};

sub _process_rules{
    my ($self, $rules) = @_;

    my $ra = Regexp::Assemble->new( track => 1 )->add( keys %$RULES_DISPATCH );

    foreach my $category (keys %$rules){
        DEBUG "Category: $category";
        foreach my $header (keys %{ $rules->{$category} }){
            my $value = $rules->{$category}{$header};
            next unless defined $value;

            DEBUG "Attempting to dispatch on header $header";
            if( $ra->match($header) ){
                my $matched = $ra->matched;
                my ($condition) = $ra->capture;
                $RULES_DISPATCH->{$matched}->($self,$category,$value,$condition);
            }
        }
    }

    return;
}

# Generate report matrix
# FIXME: rename this to generate_report and alter calling methods
sub generate_top_level_report_for_sponsors {
    my ( $self ) = @_;

    DEBUG 'Generating report for '.$self->targeting_type.' projects for species '.$self->species;

    # hashref of {category}{item} -> value
    my $data = {};
    foreach my $category (@{ $self->categories }){
        # Do we have base sql query?
          # value = result of sql query with any modifiers
        # Else do we have base method?
          # value = result of base method with any modifiers
        # Else ERROR - we do not know what to do
        my ($sql_to_exectute, $methods_to_run);
        if(my $queries = $self->category_sql->{$category}){
            $sql_to_exectute = $queries->{'base'};
            if(my $modifier = $queries->{'modifier'}){
                $sql_to_exectute.=" $modifier";
            }
        }
        else{
            # FIXME: look for methods to run
        }
        # die if no SQL or method specified

        foreach my $item (@{ $self->items }){
            if($sql_to_exectute){
                # FIXME: check for conditional modifiers which apply to some items
                # but not all
                my $result = $self->run_count_sql_query($sql_to_exectute, $item);
                DEBUG "Result for $category $item: ";
                DEBUG Dumper($result);
                $data->{$category}{$item} = $result;
            }
            else{
                # FIXME: check for conditional perl modifiers which apply to some items
                # run base, modififer and conditional methods
            }

            # Do we have styling rule for this category?
              # Apply styling rule to value and store styling params
              # FIXME: this is not yet passed to template toolkit
              # will have to add this to existing templates
        }
    }

    my ($columns, $rows);
    if($self->categories_as_columns){
        # Add blank for first column (FIXME: need to configure name of column)
        $columns = [ '', @{ $self->categories} ];
        $rows = $self->items;
    }
    else{
        $columns = [ $self->category_name, @{ $self->items } ];
        $rows = $self->categories;
    }

    my %return_params = (
        'report_id'      => $self->report_id,
        'title'          => $self->build_page_title,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    return \%return_params;
}

sub build_page_title {
    my $self = shift;

    # TODO: This date should relate to a timestamp indicating when summaries data was
    # last generated rather than just system date.
    my $dt = DateTime->now();

    return 'Pipeline Summary Report ('.$self->species.', '.$self->targeting_type.' projects) on ' . $dt->dmy;
};

sub run_items_sql{
    my ( $self, $sql_query ) = @_;

    my $results = $self->run_sql_query($sql_query);

    # results is an arrayref of hashes like { sponsor_id => 'Transfacs' }
    # we only need the values
    my @items;
    foreach my $result (@$results){
        my (@values) = values %$result;
        if(@values > 1){
            die "Item query returned more than one value per result: ".(join ",", @values);
        }
        push @items, $values[0];
    }

    return \@items;
}

sub run_count_sql_query{
    my ($self, $sql_query, $item) = @_;

    # We are expecting an arrayref containing a single hasref result like this:
    # [ { count => '123' } ]

    my $result = $self->run_sql_query($sql_query, $item);
    my @results = @$result;

    if(@results > 1){
        die "Count query produced more than 1 result";
    }

    my @values = values %{ $results[0] };
    if(@values > 1){
        die "Count query produced a result containing more than 1 value";
    }

    return $values[0];
}

# Generic method to run select SQL
sub run_sql_query {
   my ( $self, $sql_query, $item ) = @_;

   $sql_query = $self->substitue_query_variables($sql_query, $item);

   DEBUG "Running SQL $sql_query";
   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         $sth->fetchall_arrayref({

         });
      }
    );
    DEBUG "Query results: ".Dumper($sql_result);

    return $sql_result;
}

sub substitue_query_variables{
    my ($self, $sql, $item) = @_;

    my $species = $self->species;
    my $targeting_type = $self->targeting_type;

    # FIXME: really we should $dbh->prepare the generic sql query
    # for the category and use ? placeholder in sql
    if($item){
        $sql =~ s/\$item/$item/g;
    }

    $sql =~ s/\$species/$species/g;
    $sql =~ s/\$targeting_type/$targeting_type/g;

    return $sql;
}

# Generic method to execute a bit of perl code from config file
# Try this and see example on perlmonks: http://www.perlmonks.org/?node_id=886415
sub execute_perl{
    my ( $self, $perl_string ) = @_;

    my $output = eval "$perl_string";

    return $output;
}

sub set_base_sql_for_category{
    my ($self,$category,$value) = @_;
    my $sql;
    if( my ($name) = ($value =~ /base:SQL:(.*)/) ){
        $sql = $self->base_sql_queries->{$name};
        die "No base SQL query found with name $name" unless $sql;
    }
    else{
        $sql = $value;
    }

    $self->set_category_sql($category,'base',$sql);
    return;
}

sub set_modifier_sql_for_category{
    my ($self,$category,$value) = @_;
    my $sql;
    if( my ($name) = ($value =~ /modifier:SQL:(.*)/) ){
        $sql = $self->sql_query_modifiers->{$name};
        die "No modifier SQL query found with name $name" unless $sql;
    }
    else{
        $sql = $value;
    }

    $self->set_category_sql($category,'modifier',$sql);
    return;
}

sub set_category_sql{
    my ($self, $category, $type, $sql) = @_;

    if(exists $self->category_sql->{$category}{$type}){
        die "$type SQL already set for $category";
    }

    $self->category_sql->{$category}{$type} = $sql;
}

sub set_base_method_for_category{

}

sub set_modifier_method_for_category{

}

sub set_conditional_modifier_for_category{

}
1;
