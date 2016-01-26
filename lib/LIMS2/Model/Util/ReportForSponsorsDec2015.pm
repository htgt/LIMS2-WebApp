package LIMS2::Model::Util::ReportForSponsorsDec2015;

use Moose;
use Hash::MoreUtils qw( slice_def );

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

# Hash to contain any extra params which need to be set
# by the controller on a per-report basis instead of in the config
# e.g. sponsor_id in the sponsor progress sub reports
# The hash keys can be used as variable names in SQL from the config
# and will be substituted before SQL execution
has custom_params => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 0,
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

# Name of a template toolkit file available in root/lib
# which contains block to provide custom display for some categories
has helper_tt => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
);

# Name of module that provides perl methods which can be referenced in the config file
# Module should have a "new" method
has helper_module_name => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
);

has report_helper => (
    is        => 'ro',
    isa       => 'Object',
    required  => 0,
    lazy_build => 1,
);

sub _build_report_helper{
    my $self = shift;
    my $name = $self->helper_module_name
        or die "helper_module_name has not been set";
    eval "require $name";
    if( $@ ){
       die("Cannot load helper module $name : $@");
    }

    # We should already have the list of items at this point
    # because this method/query is executed during parsing of config
    # at BUILD
    my $helper = $name->new({
        species => $self->species,
        model   => $self->model,
        targeting_type => $self->targeting_type,
        custom_params  => $self->custom_params,
        items   => $self->items,
    }) or die "cannot create new report_helper $name instance";

    return $helper;
}

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

# Hash of categories which are not to be displayed as columns/rows in the report
# They can be accessed in the data hash for use in providing formatting
has do_not_display_category => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

has hide_from_public => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

has categories_for_sort => (
    is        => 'rw',
    isa       => 'ArrayRef',
    required  => 0,
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

# Name for the types of items reported, e.g. 'Sponsor' or 'Gene'
has item_name => (
    is         => 'rw',
    isa        => 'Str',
    required   => 0,
    default    => 'Item'
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


# Hash of base and modifier sql for each category
has category_sql => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of base and modifier perl methods for each category
# These methods must be implemented by the report_helper_module
# Base method will be called once per item and base output will be stored
# Modifier methods will be called for each item-category and will be
# passed the result of the base method followed by any category_modifier:METHOD_ARGS
has category_method => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Store of base method results: method_name->item->result
has base_method_results => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 0,
    default    => sub{ {} },
);

# Hash of formatters to style the cell for each category
# Formatters must be named BLOCKs in the helper_tt file
has category_formatter => (
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

    DEBUG "Category SQL: ".Dumper($self->category_sql);

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
    'item_name'             => sub { my ($self,$value) = @_; $self->item_name($value) },
    'report_id'             => sub { my ($self,$value) = @_; $self->report_id($value) },
    'categories_as_columns' => sub { my ($self,$value) = @_; $self->categories_as_columns($value) },
    'helper_module'         => sub { my ($self,$value) = @_; $self->helper_module_name($value) },
    'helper_tt'             => sub { my ($self,$value) = @_; $self->helper_tt($value) },
    'items:SQL'             => sub { my ($self,$value) = @_; $self->items( $self->run_items_sql($value) ) },
    'items:PERL'            => sub { my ($self,$value) = @_; $self->items( $self->execute_perl($value) ) },
    'base:SQL:(.*)'         => sub { my ($self,$value,$name) = @_; $self->base_sql_queries->{$name} = $value; },
    'modifier:SQL:(.*)'     => sub { my ($self,$value,$name) = @_; $self->sql_query_modifiers->{$name} = $value; },
    'sort_by'               => sub { my ($self,$value) = @_; $self->set_sort_by_categories($value) },
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

    # Do this after the dispatch methods as item_name must be set first
    if(defined $settings->{item_formatter}){
        $self->category_formatter->{ $self->item_name } = $settings->{item_formatter};
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
    'category_base:SQL'      => sub { my ($self,$cat,$val) = @_; $self->set_base_sql_for_category($cat,$val) },
    'category_modifier:SQL'  => sub { my ($self,$cat,$val) = @_; $self->set_modifier_sql_for_category($cat,$val) },
    'condition:(.*)'         => sub { my ($self,$cat,$val,$condition) = @_; $self->set_conditional_sql_for_category($cat,$val,$condition) },
    'category_base:METHOD'          => sub { my ($self,$cat,$val) = @_; $self->set_base_method_for_category($cat,$val) },
    'category_modifier:METHOD'      => sub { my ($self,$cat,$val) = @_; $self->set_modifier_method_for_category($cat,$val) },
    'category_modifier:METHOD_ARGS' => sub { my ($self,$cat,$val) = @_; $self->set_modifier_method_args_for_category($cat,$val) },
    'formatter'              => sub { my ($self,$cat,$val) = @_; $self->category_formatter->{$cat} = $val },
    'do_not_display'         => sub{ my ($self,$cat,$val) = @_; if($val){ $self->do_not_display_category->{$cat} = $val } },
    'hide_from_public'       => sub{ my ($self,$cat,$val) = @_; if($val){ $self->hide_from_public->{$cat} = $val } },
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

# Generate report data
sub generate_report {
    my ( $self, $report_specific_params ) = @_;

    DEBUG 'Generating report for '.$self->targeting_type.' projects for species '.$self->species;

    # hashref of {category}{item} -> value
    my $data = {};
    foreach my $category (@{ $self->categories }){
        # Do we have base sql query?
          # value = result of sql query with any modifiers
        # Else do we have base method?
          # value = result of base method with any modifiers
        # Else ERROR - we do not know what to do
        my ($sql_to_exectute, $conditional_sql);
        my ($base_method,$modifier_method,$modifier_args);

        if(my $queries = $self->category_sql->{$category}){
            $sql_to_exectute = $queries->{'base'};
            if(my $modifier = $queries->{'modifier'}){
                $sql_to_exectute.=" $modifier";
            }
            $conditional_sql = $queries->{'conditional'} || {};
        }
        elsif(my $methods = $self->category_method->{$category}){
            # Find the base a modifier methods and args for category
            $base_method = $methods->{'base'};
            if($methods->{'modifier'}){
                $modifier_method = $methods->{'modifier'};
                if($methods->{'modifier_args'}){
                    $modifier_args = $methods->{'modifier_args'};
                }
            }
        }
        else{
            die "No SQL or perl methods found for category $category";
        }


        foreach my $item (@{ $self->items }){
            if($sql_to_exectute){

                my $sql_with_conditional = $self->_add_conditional_sql($sql_to_exectute, $conditional_sql, $item);

                my $result = $self->run_count_sql_query($sql_with_conditional, $item);
                DEBUG "Result for $category $item: ";
                DEBUG Dumper($result);
                $data->{$category}{$item} = $result;
            }
            else{
                my $base_result = $self->get_base_method_result($base_method,$item);
                my $result = $self->get_modifier_method_result($base_result, $modifier_method, $modifier_args);
                DEBUG "Method result for $category $item: ";
                DEBUG Dumper($result);
                $data->{$category}{$item} = $result;
            }
        }
    }

    my ($columns, $rows);
    if($self->categories_as_columns){

        $columns = [ $self->item_name, @{ $self->categories} ];
        $rows = $self->items;
        # FIXME: I am altering the structure of data because of the way sponsor_sub_report.tt
        # handles the rows and columns but should instead create a generic tt grid which
        # correctly searches data as category->item = value and uses the categories_as_columns
        # flag to work out that category = col and item = row in this case
        my $new_data = {};
        foreach my $category (keys %$data){
            foreach my $item (keys %{ $data->{$category} }){
                $new_data->{$item} ||= {};
                $new_data->{$item}->{$category} = $data->{$category}->{$item};
            }
        }
        $data = $new_data;
    }
    else{
        $columns = [ $self->category_name, @{ $self->items } ];
        $rows = $self->categories;
    }

    my @display_columns = @$columns;
    my @sorted_rows = @$rows;
    if($self->categories_as_columns){
        @display_columns = grep { !$self->do_not_display_category->{$_} } @$columns;
        @sorted_rows = $self->sort_rows($rows,$data);
    }

    my %return_params = (
        'report_id'      => $self->report_id,
        'title'          => $self->build_page_title,
        'columns'        => $columns,
        'display_columns' => \@display_columns,
        'rows'           => \@sorted_rows,
        'data'           => $data,
    );

    return \%return_params;
}

sub sort_rows{
    my ($self,$rows,$data) = @_;

    unless($self->categories_for_sort){
        return @$rows;
    }

    # Build the search expression as a string
    my $sort_expression;
    foreach my $category (@{ $self->categories_for_sort }){
        if($sort_expression){
            $sort_expression .= '|| $b->{\''.$category.'\'} <=> $a->{\''.$category.'\'} ';
        }
        else{
            $sort_expression = '$b->{\''.$category.'\'} <=> $a->{\''.$category.'\'} ';
        }
    }
    $self->log->debug("Sort expression: $sort_expression");

    # Prepare data for comparison by getting 'total' if data is a hashref
    # and replacing undef entries with -1
    my @data_for_sort;
    foreach my $row (@$rows){
        my $compare_hash = {
            row_id => $row,
        };
        foreach my $category (@{ $self->categories_for_sort }){
            my $value = $data->{$row}->{$category};
            my $compare_val;
            if(ref $value eq ref{}){
                $compare_val = $value->{total} // -1;
            }
            else{
                $compare_val = $value // -1;
            }
            $compare_hash->{$category} = $compare_val;
        }
        push @data_for_sort, $compare_hash;
    }

    # Run the sort expression and map back to original row ids
    my @sorted_rows = map { $_->{row_id} } sort { eval $sort_expression } @data_for_sort;
}

sub build_page_title {
    my $self = shift;

    # TODO: This date should relate to a timestamp indicating when summaries data was
    # last generated rather than just system date.
    my $dt = DateTime->now();

    return 'Pipeline Summary Report ('.$self->species.', '.$self->targeting_type.' projects) on ' . $dt->dmy;
};

sub _add_conditional_sql{
    my ($self, $sql_to_exectute, $conditional_sql, $item) = @_;

    my $species = $self->species;
    while (my ($condition, $sql) = each %$conditional_sql){
        DEBUG "Evaluating condition $condition for item $item";
        if(eval "$condition"){
            DEBUG "Eval returned TRUE";
            $sql_to_exectute.=" $sql";
        }
    }
    return $sql_to_exectute;
}

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

    if (my $extra_vars = $self->custom_params){
        foreach my $key (keys %$extra_vars ){
            my $value = $extra_vars->{$key};
            $sql =~ s/\$$key/$value/g;
        }
    }
    return $sql;
}

sub get_base_method_result{
    my ($self,$base_method,$item) = @_;

    my $existing_results = $self->base_method_results->{$base_method} ||{};
    my $result = $existing_results->{$item};

    unless($result){
        # We have not yet executed the base method for this item so do it now
        # FIXME: need some error handling here
        DEBUG "Running base method $base_method on item $item";
        $result = $self->report_helper->$base_method($item);

        # Store the result
        $self->base_method_results->{$base_method} ||= {};
        $self->base_method_results->{$base_method}->{$item} = $result;
    }

    return $result;
}

sub get_modifier_method_result{
    my ($self, $base_result, $modifier_method, $modifier_args) = @_;

    $modifier_args ||= [];

    DEBUG "Running modifier method $modifier_method";
    my $result = $self->report_helper->$modifier_method($base_result,@$modifier_args);

    return $result;
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

sub set_conditional_sql_for_category{
    my ($self, $category, $value, $condition) = @_;

    $self->category_sql->{$category} ||= {};
    $self->category_sql->{$category}->{'conditional'} ||= {};
    $self->category_sql->{$category}->{'conditional'}->{$condition} = $self->get_sql_for_value($value);
    return;
}

sub get_sql_for_value{
    my ($self, $value) = @_;
    # Check if the given value is a refernce to a predefined SQL statement
    # or if it is raw SQL. Return the SQL.
    my $sql;
    if( my ($name) = ($value =~ /modifier:SQL:(.*)/) ){
        $sql = $self->sql_query_modifiers->{$name};
        die "No modifier SQL query found with name $name" unless $sql;
    }
    else{
        $sql = $value;
    }
    return $sql;
}

sub set_category_sql{
    my ($self, $category, $type, $sql) = @_;

    if(exists $self->category_sql->{$category}{$type}){
        die "$type SQL already set for $category";
    }

    $self->category_sql->{$category}{$type} = $sql;
    return;
}

sub set_base_method_for_category{
    my ($self,$category,$value) = @_;
    $self->set_category_method($category,'base',$value);
    return;
}

sub set_modifier_method_for_category{
    my ($self,$category,$value) = @_;
    $self->set_category_method($category,'modifier',$value);
    return;
}

sub set_modifier_method_args_for_category{
    my ($self,$category,$value) = @_;
    my @args = split /\s*;\s*/, $value;
    $self->set_category_method($category,'modifier_args',\@args);
    return;
}

sub set_conditional_method_for_category{
    # FIXME: not yet implemented
}

sub set_category_method{
    my ($self,$category,$type,$value) = @_;

    if(exists $self->category_method->{$category}{$type}){
        die "$type method already set for $category";
    }

    $self->category_method->{$category}{$type} = $value;
    return;
}

sub set_sort_by_categories{
    my ($self,$value) = @_;
    my @categories = split /\s*;\s*/, $value;
    $self->categories_for_sort(\@categories);
}
1;
