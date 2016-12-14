use utf8;
package LIMS2::Model::Schema::Result::Plate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Plate::VERSION = '0.437';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Plate

=cut

use strict;
use warnings;
use Try::Tiny;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<plates>

=cut

__PACKAGE__->table("plates");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'plates_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_virtual

  data_type: 'boolean'
  is_nullable: 1

=head2 barcode

  data_type: 'text'
  is_nullable: 1

=head2 sponsor_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 version

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "plates_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "created_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "is_virtual",
  { data_type => "boolean", is_nullable => 1 },
  "barcode",
  { data_type => "text", is_nullable => 1 },
  "sponsor_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "version",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<plates_name_version_key>

=over 4

=item * L</name>

=item * L</version>

=back

=cut

__PACKAGE__->add_unique_constraint("plates_name_version_key", ["name", "version"]);

=head1 RELATIONS

=head2 barcode_events_new_plates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_new_plates",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.new_plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 barcode_events_old_plates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BarcodeEvent>

=cut

__PACKAGE__->has_many(
  "barcode_events_old_plates",
  "LIMS2::Model::Schema::Result::BarcodeEvent",
  { "foreign.old_plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 created_by

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "LIMS2::Model::Schema::Result::User",
  { id => "created_by_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_plate_append

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::CrisprPlateAppend>

=cut

__PACKAGE__->might_have(
  "crispr_plate_append",
  "LIMS2::Model::Schema::Result::CrisprPlateAppend",
  { "foreign.plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_comments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::PlateComment>

=cut

__PACKAGE__->has_many(
  "plate_comments",
  "LIMS2::Model::Schema::Result::PlateComment",
  { "foreign.plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sponsor

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Sponsor>

=cut

__PACKAGE__->belongs_to(
  "sponsor",
  "LIMS2::Model::Schema::Result::Sponsor",
  { id => "sponsor_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::PlateType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "LIMS2::Model::Schema::Result::PlateType",
  { id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 wells

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->has_many(
  "wells",
  "LIMS2::Model::Schema::Result::Well",
  { "foreign.plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-02-03 13:41:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FwSGsovECFvj2EVxMP3SPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use overload '""' => \&as_string;
use List::MoreUtils qw(any);

sub as_string {
    my $self = shift;

    my $name = $self->name;

    if($self->version){
        $name = sprintf( '%s(v%s)', $self->name, $self->version);
    }

    return $name;
}

sub as_hash {
    my $self = shift;

    return {
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        type        => $self->type_id,
        created_by  => $self->created_by->name,
        created_at  => $self->created_at->iso8601,
        wells       => [ sort map { $_->name } $self->wells ]
    };
}

sub has_child_wells {
    my $self = shift;

    for my $well ( $self->wells ) {
        return 1 if $well->process_input_wells > 0;
    }

    return;
}

sub parent_plates_by_process_type{
	my $self = shift;
	my $parents;

	for my $well ( $self->wells ){
	    foreach my $process ($well->parent_processes){
	    	my $type = $process->type_id;
	    	$parents->{$type} ||= {};
	    	foreach my $input ($process->input_wells){
          try{
  	    		my $plate = $input->plate;
  	    		$parents->{$type}->{$plate->name} = $plate;
          };
	      }
	    }
	}

	return $parents;
}

sub parent_names {
    my $self = shift;
    my @ancestors;
    for my $well ( $self->wells ){
	    foreach my $process ($well->parent_processes){
	    	foreach my $input ($process->input_wells){
                my $plate = {
                    name => $input->plate_name,
                    type_id => $input->plate_type,
                };
                push (@ancestors, $plate);
	        }
	    }
	}

    return \@ancestors;
}

sub child_plates_by_process_type{
	my $self = shift;

	my $children;

	for my $well ( $self->wells ){
	    foreach my $process ($well->child_processes){
	    	my $type = $process->type_id;
	    	$children->{$type} ||= {};
	    	foreach my $output ($process->output_wells){
	    		my $plate = $output->plate;
	    		$children->{$type}->{$plate->name} = $plate;
	        }
	    }
	}

	return $children;
}

sub number_of_wells {
    my $self = shift;

    my $count = 0;
    for my $well ( $self->wells ){
      $count += 1;
    }

    return $count;
}

sub number_of_wells_with_barcodes {
    my $self = shift;

    my $count = 0;
    for my $well ( $self->wells ){
      if( $well->barcode ) {
        $count += 1;
      }
    }

    return $count;
}

sub has_global_arm_shortened_designs{
    my $self = shift;
    return any { $_->global_arm_shortened_design } $self->wells;
}
__PACKAGE__->meta->make_immutable;
1;
