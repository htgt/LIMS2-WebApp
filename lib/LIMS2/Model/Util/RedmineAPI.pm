package LIMS2::Model::Util::RedmineAPI;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::RedmineAPI::VERSION = '0.467';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use List::MoreUtils qw( uniq any );
use LIMS2::Exception;
use TryCatch;
use Data::Dumper;
use WWW::JSON;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

has '+configfile' => (
    default => $ENV{REDMINE_API_CONFIG},
);

has redmine_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has access_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has project_identifier => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has project_id => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build => 1,
);

sub _build_project_id {
    my $self = shift;
    my $get = $self->get('projects.json');

    my ($project) = grep { $_->{identifier} eq $self->project_identifier } @{ $get->res->{projects} };

    die "Cannot find project ".$self->project." in redmine tracker at ".$self->redmine_url unless $project;
    return $project->{id};
}

has redmine => (
    is       => 'ro',
    isa      => 'WWW::JSON',
    lazy_build => 1,
    handles    => [ qw(get put post delete) ],
);

sub _build_redmine {
    my $self = shift;

    $self->log->debug("Creating redmine JSON API");

    my $redmine = WWW::JSON->new({
        base_url => $self->redmine_url,
        post_body_format => 'JSON',
        authentication => { 'Basic' => { username => $self->access_key, password => 'random' } },
    });

    return $redmine;
}

has custom_field_id_for => (
    is    => 'ro',
    isa   => 'HashRef',
    lazy_build => 1,
);

sub _build_custom_field_id_for{
    my $self = shift;

    # Fetch a single issue
    # Use it to build map of custom field names to IDs
    my $params = {
        limit => 1,
        project_id => $self->project_id,
    };

    my $get = $self->get("issues.json",$params);
    my $issue = $get->res->{issues}->[0];

    my $fields = $issue->{custom_fields};
    my $name_to_id = {};
    foreach my $field (@$fields){
        $name_to_id->{ $field->{name} } = $field->{id};
    }

    return $name_to_id;
}

has tracker_id_for => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_tracker_id_for{
    my $self = shift;

    my $get = $self->get("trackers.json");
    my $trackers = $get->res->{trackers};

    my %tracker_names_to_ids = map { $_->{name} => $_->{id} } @{ $trackers };
    return \%tracker_names_to_ids;
}

has priority_id_for => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_priority_id_for{
    my $self = shift;

    my $get = $self->get("/enumerations/issue_priorities.json");
    my $priorities = $get->res->{issue_priorities};

    my %pr_to_ids = map { lc( $_->{name} ) => $_->{id} } @{ $priorities };
    return \%pr_to_ids;
}

has status_id_for => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_status_id_for{
   my $self = shift;

   my $get = $self->get("issue_statuses.json");

   $self->log->debug("Statuses: ".Dumper($get->res));

   my $statuses = $get->res->{issue_statuses};
   my %name_to_id = map { $_->{name} => $_->{id} } @{ $statuses };
   return \%name_to_id;
}

sub get_issues{
    my ($self, $params, $custom_field_params) = @_;
    $params ||= {};

    # Custom field values can be used to filter results
    # but we need to map field name to ID first
    if($custom_field_params){
        while ( my($name, $value) = each %{ $custom_field_params } ){
            my $field_id = $self->custom_field_id_for->{$name}
                or die "No custom field ID identified for category $name";

            $params->{'cf_'.$field_id} = $value;
        }
    }

    # Add redmine project id param
    $params->{project_id} = $self->project_id;

    my @all_issues;
    my $offset = 0;
    my $limit = 100; # tried to increase this to 1000 but only got 100 results

    # Add paging params
    $params->{limit} = $limit;
    $params->{offset} = $offset;

    $self->log("Offset: $offset");
    my $first_page = $self->get("issues.json",$params);

    push @all_issues, @{ $first_page->res->{issues} };
    my $total = $first_page->res->{total_count};

    # Get issues from any additional pages
    while(scalar @all_issues < $total ){
        $offset += $limit;
        $params->{offset} = $offset;
        $self->log("Offset: $offset");
        my $next_page = $self->get("issues.json",$params);
        push @all_issues, @{ $next_page->res->{issues}};
    }

    # Add url for the issue (user view, not api)
    foreach my $issue (@all_issues){
        $self->_prepare_issue_for_lims2($issue);
    }

    return \@all_issues;
}

sub _pspec_create_issue{
    return {
        tracker_name  => { validate => 'non_empty_string' },
        gene_id       => { validate => 'non_empty_string' },
        gene_symbol   => { validate => 'non_empty_string' },
        project_id    => { validate => 'existing_project_id' },
        sponsors      => { validate => 'non_empty_string' },
        cell_line     => { validate => 'existing_cell_line' },
        experiment_id => { validate => 'existing_experiment_id'},
        description   => { validate => 'non_empty_string', optional => 1},
        priority      => { validate => 'non_empty_string', optional => 1},
    };
}

sub create_issue{
    my ($self, $model, $params) = @_;

    $model->check_params($params, $self->_pspec_create_issue);

    my @sponsors = grep { $_ ne 'All' } split "/", $params->{sponsors};

    # Change cell line names to match those in redmine list
    my $cell_line = $params->{cell_line};
    $cell_line =~ s/_/-/g;

    my $experiment = $model->retrieve_experiment({ id => $params->{experiment_id} });

    # Marker_Symbol, Sponsor (list), Project ID, HGNC ID, Current Experiment ID, Cell Line
    # Chromosome (we could get chr_name from experiment design/crispr entity)
    my $custom_fields = [
        {
            id    => $self->custom_field_id_for->{'Marker_Symbol'},
            value => $params->{gene_symbol},
        },
        {
            id    => $self->custom_field_id_for->{'Sponsor'},
            value => \@sponsors,
        },
        {
            id    => $self->custom_field_id_for->{'Project ID'},
            value => $params->{project_id},
        },
        {
            id    => $self->custom_field_id_for->{'HGNC ID'},
            value => $params->{gene_id},
        },
        {
            id    => $self->custom_field_id_for->{'Cell Line'},
            value => $cell_line,
        },
        {
            id    => $self->custom_field_id_for->{'Human Allele'},
            value => 'CRISPR Homozygous', # Setting all as CRISPR homozygous
        },
        {
            id    => $self->custom_field_id_for->{'Current Experiment ID'},
            value => $params->{experiment_id},
        },
        {
            id    => $self->custom_field_id_for->{'Chromosome'},
            value => $experiment->chr_name,
        },
    ];

    my $issue_info = {
      "issue" => {
            "tracker_id"    => $self->tracker_id_for->{ $params->{tracker_name} },
            "project_id"    => $self->project_id, # this is the redmine project ID
            "subject"       => $params->{gene_symbol},
            "description"   => $params->{description} // "",
            "custom_fields" => $custom_fields,
        }
    };

    if(my $pr_name = $params->{priority}){
        $pr_name = lc($pr_name);
        my $priority_id = $self->priority_id_for->{ $pr_name };
        if($priority_id){
            $issue_info->{issue}->{priority_id} = $priority_id;
        }
        else{
            die "No priority named $pr_name found in redmine";
        }
    }
    # Show ticket as created by LIMS2
    $self->redmine->default_header( 'X-Redmine-Switch-User' => 'lims2' );

    my $post = $self->post('issues.json',$issue_info);
    $self->redmine->default_header( 'X-Redmine-Switch-User' => '' );

    my $new_issue = $post->res->{issue}
        or die "Could not create issue: ".Dumper $post->res;

    $self->_prepare_issue_for_lims2($new_issue);

    return $new_issue;
}

sub update_issue_status{
    my ($self, $issue_id, $new_status, $comment) = @_;

    my $status_id = $self->status_id_for->{$new_status}
        or die "Could not find ID for status $new_status";

    my $update_info = {
        issue => {
            status_id => $status_id,
        }
    };

    if($comment){
        $update_info->{issue}->{notes} = $comment;
    }

    $self->redmine->default_header( 'X-Redmine-Switch-User' => 'lims2' );
    my $target = "issues/$issue_id.json";
    my $put = $self->put($target, $update_info);

    my $updated_issue;
    if($put->success){
        # Check it has updated status
        my $get = $self->get($target);
        my $issue = $get->res->{issue};
        if( $issue->{status}->{name} eq $new_status){
            # It worked, return issue
            return $updated_issue;
        }
        else{
            die "Issue $issue_id status not updated to $new_status. Current status is "
                .$issue->{status}->{name};
        }
    }
    else{
        die "Failed to update issue $issue_id status: ".$put->error;
    }
    return $updated_issue;
}

# custom_fields is an array of hashes containing id, name, value
# convert it to a single hash of name => value pairs
# add issue url
sub _prepare_issue_for_lims2{
    my ($self,$issue) = @_;

    my $fields = delete $issue->{custom_fields};
    my $hash = {};
    foreach my $field (@$fields){
        $hash->{ $field->{name} } = $field->{value};
    }
    $issue->{custom_fields} = $hash;

    $issue->{url} = $self->redmine_url."/issues/".$issue->{id};

    return $issue;
}

1;