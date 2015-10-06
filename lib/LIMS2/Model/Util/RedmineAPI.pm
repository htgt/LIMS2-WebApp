package LIMS2::Model::Util::RedmineAPI;

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

has project_name => (
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
    my $projects = $self->get('projects.json');

    my ($project) = grep { $_->{identifier} eq $self->project_name } @{ $projects->res->{projects} };

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

    my $issues = $self->get("issues.json",$params);
    my $issue_json = $issues->res->{issues}->[0];

    my $fields = $issue_json->{custom_fields};
    my $name_to_id = {};
    foreach my $field (@$fields){
        $name_to_id->{ $field->{name} } = $field->{id};
    }

    return $name_to_id;
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
    my $issues = $self->get("issues.json",$params);

    push @all_issues, @{ $issues->res->{issues} };
    my $total = $issues->res->{total_count};

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
        $issue->{url} = $self->redmine_url."/issues/".$issue->{id};
    }

    my $issues_with_custom_fields = _add_custom_fields_by_name(\@all_issues);
    return $issues_with_custom_fields;
}

# custom_fields is an array of hashes containing id, name, value
# convert it to a single hash of name => value pairs
sub _add_custom_fields_by_name{
    my ($issues) = @_;

    foreach my $issue (@$issues){
        my $fields = delete $issue->{custom_fields};
        my $hash = {};
        foreach my $field (@$fields){
            $hash->{ $field->{name} } = $field->{value};
        }
        $issue->{custom_fields} = $hash;
    }
    return $issues;
}

1;