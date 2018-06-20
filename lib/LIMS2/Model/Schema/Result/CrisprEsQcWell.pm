use utf8;
package LIMS2::Model::Schema::Result::CrisprEsQcWell;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprEsQcWell::VERSION = '0.507';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprEsQcWell

=cut

use strict;
use warnings;

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

=head1 TABLE: C<crispr_es_qc_wells>

=cut

__PACKAGE__->table("crispr_es_qc_wells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_es_qc_wells_id_seq'

=head2 crispr_es_qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 fwd_read

  data_type: 'text'
  is_nullable: 1

=head2 rev_read

  data_type: 'text'
  is_nullable: 1

=head2 crispr_chr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_start

  data_type: 'integer'
  is_nullable: 1

=head2 crispr_end

  data_type: 'integer'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 analysis_data

  data_type: 'json'
  is_nullable: 0

=head2 accepted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 vcf_file

  data_type: 'text'
  is_nullable: 1

=head2 crispr_damage_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 variant_size

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_es_qc_wells_id_seq",
  },
  "crispr_es_qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "fwd_read",
  { data_type => "text", is_nullable => 1 },
  "rev_read",
  { data_type => "text", is_nullable => 1 },
  "crispr_chr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_start",
  { data_type => "integer", is_nullable => 1 },
  "crispr_end",
  { data_type => "integer", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "analysis_data",
  { data_type => "json", is_nullable => 0 },
  "accepted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "vcf_file",
  { data_type => "text", is_nullable => 1 },
  "crispr_damage_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "variant_size",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_chr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Chromosome>

=cut

__PACKAGE__->belongs_to(
  "crispr_chr",
  "LIMS2::Model::Schema::Result::Chromosome",
  { id => "crispr_chr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_damage_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprDamageType>

=cut

__PACKAGE__->belongs_to(
  "crispr_damage_type",
  "LIMS2::Model::Schema::Result::CrisprDamageType",
  { id => "crispr_damage_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_es_qc_run

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprEsQcRuns>

=cut

__PACKAGE__->belongs_to(
  "crispr_es_qc_run",
  "LIMS2::Model::Schema::Result::CrisprEsQcRuns",
  { id => "crispr_es_qc_run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 crispr_validations

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprValidation>

=cut

__PACKAGE__->has_many(
  "crispr_validations",
  "LIMS2::Model::Schema::Result::CrisprValidation",
  { "foreign.crispr_es_qc_well_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-22 07:48:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YCe585FTaxThOQPMxvnUdw

use JSON;
use List::Util qw ( min max );
use List::MoreUtils qw( uniq );
use LIMS2::Model::Util::Crisprs qw( gene_ids_for_crispr );
use Data::Dumper;
use List::MoreUtils qw( any );
use Bio::Perl qw( revcom );

use Log::Log4perl qw(:easy);
BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}


sub as_hash {
  my ( $self, $options ) = @_;

  my $data = { map { $_ => $self->$_ } $self->columns };
  delete $data->{analysis_data};

  return $data;
}

sub get_crispr_primers {
  my $self = shift;

  #get crispr primers
  my $analysis_data = decode_json( $self->analysis_data );

  #see whether we're searching for crispr pair or crispr primers
  my $field = $analysis_data->{is_pair}  ? 'crispr_pair_id'
            : $analysis_data->{is_group} ? 'crispr_group_id'
            :                              'crispr_id';

  #return a resultset of all the relevant crispr primers
  return $self->result_source->schema->resultset('CrisprPrimer')->search(
    { $field => $analysis_data->{crispr_id}, is_rejected => [0, undef] },
    { order_by => { -asc => 'me.primer_name' } }
  );
}

=head2 format_well_data

Gather and format data to be displayed for this crispr qc well.

gene finder should be a coderef pointing to a method that finds genes.
usually this will be sub { $c->model('Golgi')->find_genes( @_ ) }

=cut
## no critic(ProhibitExcessComplexity)
sub format_well_data {
    my ( $self, $gene_finder, $params, $run, $gene_ids ) = @_;

    my $json = decode_json( $self->analysis_data );

    #allow user to specify the run so we don't have to retrieve it for every well
    unless ( $run ) {
      $run = $self->crispr_es_qc_run;
    }

    #get the crispr entity to this es qc well
    my $crispr = $self->crispr;

    #get HGNC/MGI ids
    my @gene_ids;
    if ( $gene_ids ) {
        @gene_ids = @{ $gene_ids };
    }
    else {
        if ( $crispr ) {
            @gene_ids = uniq @{ gene_ids_for_crispr( $gene_finder, $crispr ) };
        }
        else {
            @gene_ids = uniq map { $_->gene_id } $self->well->design->genes;
        }
    }

    #get gene symbol from the solr
    my @genes = map { $_->{gene_symbol} }
                  values %{ $gene_finder->( $run->species_id, \@gene_ids ) };

    my ( $alignment_data, $insertions, $deletions )
        = $self->format_alignment_strings( $params, $json );

    my $show_checkbox = 1; #by default we show the accepted checkbox
    #if the well itself is accepted, we need to see if it was this run that made it so
    if ( $self->well_accepted_any_run && ! $self->accepted ) {
        #the well was accepted on another QC run
        $show_checkbox = 0;
    }
    my $has_vcf_file = $self->vcf_file ? 1 : 0;
    my $has_vep_file = exists $json->{vep_output} ? 1 : 0;
    my $has_non_merged_vcf_file = exists $json->{non_merged_vcf} ? 1 : 0;
    my $has_ref_aa_file = exists $json->{ref_aa_seq} ? 1 : 0;
    my $has_mut_aa_file = exists $json->{mut_aa_seq} ? 1 : 0;

    #move this to its own function

    #could have used tr///
    my %special_map = (
      J => 'N',
      L => 'A',
      P => 'T',
      Y => 'C',
      Z => 'G',
    );

    if($params->{truncate}){
      # Do we really need to do this?? can't we take section of fwd_read and rev_read?

      #rebuild entire sequence. insertions hash will be empty if there are none
      #this is to make finding the sequence within a trace easier
      for my $dir ( keys %{ $insertions } ) {
          my @positions = sort keys %{ $insertions->{$dir} };

          my ( $res, $i ) = ( "", 0 );
          #loop through the whole string, replacing any special chars with their insert
          for my $char ( split "", $alignment_data->{$dir} ) {
              next if $char =~ /[-X]/; #skip dashes and Xs
              #this just gets the sequence out of the insertions hash, what a nightmare
              $res .= ($char =~ /[JLPYZ]/)
                    ? $special_map{$char} . $insertions->{$dir}{ $positions[$i++] }{seq}
                    : uc $char;
          }

          #store with the other alignment data for easy access
          $alignment_data->{$dir."_full"} = $res;
      }
    }
    else{
        # We are looking at the complete read so can just get it from the database
        if($self->fwd_read){
            my ($name, $seq) = split "\n", $self->fwd_read;
            $alignment_data->{'forward_full'} = $seq;
        }

        if($self->rev_read){
            my ($name, $seq) = split "\n", $self->rev_read;
            $alignment_data->{'reverse_full'} = revcom( $seq )->seq;
        }
    }

    return {
        es_qc_well_id           => $self->id,
        well_id                 => $self->well->id,
        well_name               => $self->well->name, #fetch the well and get name
        crispr_id               => $json->{crispr_id} || "",
        is_crispr_pair          => $json->{is_pair} || "",
        is_crispr_group         => $json->{is_group} || "",
        ranked_crisprs          => $self->ranked_crisprs( $crispr ),
        gene                    => join( ",", @genes ),
        alignment               => $alignment_data,
        longest_indel           => $json->{concordant_indel} || "",
        qc_well_accepted        => $self->accepted,
        well_accepted           => $self->well->accepted,
        show_checkbox           => $show_checkbox,
        insertions              => $insertions,
        deletions               => $deletions,
        has_vcf_file            => $has_vcf_file,
        has_non_merged_vcf_file => $has_non_merged_vcf_file,
        has_vep_file            => $has_vep_file,
        has_ref_aa_file         => $has_ref_aa_file,
        has_mut_aa_file         => $has_mut_aa_file,
        fwd_read                => $self->fwd_read,
        rev_read                => $self->rev_read,
        damage_type             => $self->crispr_damage_type_id,
        vep_output              => $json->{vep_output},
        variant_size            => $self->variant_size,
        gene_ids                => \@gene_ids,
    };
}
## use critic

=head2 crispr

Return the crispr entity linked to the well.
Could be a crispr, crispr pair or crispr group.

=cut
sub crispr {
  my ( $self, $json ) = @_;

  #optionally allow user to provide the json string so we don't have to always decode
  unless ( $json ) {
    $json = decode_json( $self->analysis_data );
  }

  return if $json->{no_crispr};

  my $crispr;

  my ( $rs, $prefetch );
  if ( $json->{is_pair} ) {
      $rs = 'CrisprPair';
      $prefetch = [ 'left_crispr', 'right_crispr', 'experiments' ];
  }
  elsif ( $json->{is_group} ) {
      $rs = 'CrisprGroup';
      $prefetch = [ ];
  }
  else {
      $rs = 'Crispr';
      $prefetch = [ 'experiments' ];
  }

  $crispr = $self->result_source->schema->resultset($rs)->find(
      { id => $json->{crispr_id} },
      { prefetch => $prefetch }
  );

  return $crispr;
}

=head2 ranked_crisprs

Return array of crisprs ranked from left to right.

=cut
sub ranked_crisprs {
    my ( $self, $crispr ) = @_;
    return [  ] unless $crispr;

    my %crispr_validations = map{ $_->crispr_id => $_->validated } $self->crispr_validations->all;

    my @ranked_crisprs;
    if ( $crispr->is_group ) {
        @ranked_crisprs = map{ _ranked_crispr_data( $_, \%crispr_validations ) } @{ $crispr->ranked_crisprs };
    }
    elsif ( $crispr->is_pair ) {
        @ranked_crisprs = (
            _ranked_crispr_data( $crispr->left_crispr, \%crispr_validations ),
            _ranked_crispr_data( $crispr->right_crispr, \%crispr_validations ),
        );
    }
    else {
        push @ranked_crisprs, _ranked_crispr_data( $crispr, \%crispr_validations );
    }

    return \@ranked_crisprs;
}

=head2 _ranked_crispr_data

Get crispr data we need for ranked crisprs ( used in validate crispr interface )

=cut
sub _ranked_crispr_data {
    my ( $crispr, $crispr_validations ) = @_;

    return {
        id        => $crispr->id,
        validated => exists $crispr_validations->{ $crispr->id } ? $crispr_validations->{ $crispr->id }  : 0,
    };
}

## no critic(ProhibitExcessComplexity)
sub format_alignment_strings {
    my ( $self, $params, $json ) = @_;

    return { forward => 'No Read', reverse => 'No Read', no_reverse_read => 1, no_forward_read => 1 } if $json->{no_reads};
    return { forward => 'No valid crispr', reverse => 'No valid crispr' , no_reverse_read => 1, no_forward_read => 1} if $json->{no_crispr};

    if ( $json->{forward_no_alignment} && $json->{reverse_no_alignment} ) {
        if ( !$self->fwd_read ) {
            return { forward => 'No Read', no_forward_read => 1, no_reverse_alignment => 1 };
        }
        elsif ( !$self->rev_read ) {
            return { reverse => 'No Read', no_reverse_read => 1, no_forward_alignment => 1 };
        }
        else {
            return { no_forward_alignment => 1, no_reverse_alignment => 1 };
        }
    }

    # TODO refactor this
    my $insertion_data = $json->{insertions};
    my $insertions;
    for my $position ( keys %{ $insertion_data } ) {
        for my $insertion ( @{ $insertion_data->{$position} } ) {
            $insertions->{ $insertion->{read} }{ $position } = $insertion;
        }
    }

    my $deletion_data = $json->{deletions};
    my $deletions;
    for my $position ( keys %{ $deletion_data } ) {
        for my $deletion ( @{ $deletion_data->{$position} } ) {
            $deletions->{ $deletion->{read} }{ $position } = $deletion;
        }
    }

    #get start, end and size data relative to our seq strings
    my $localised = $self->get_localised_pair_coords( $json );

    #extract read sequence and its match string
    my %alignment_data = (
        forward => $json->{forward_sequence} || '',
        reverse => $json->{reverse_sequence} || '',
    );

    #forward and reverse will have the same target_align_str
    #this is the reference sequence
    my $seq = $json->{ref_sequence} || "";

    #truncate sequences if necessary,
    #and split the target align seq into three parts: before, crispr, after
    my $padding;
    if ( $params->{truncate} ) {
        $padding = defined $params->{padding} ? $params->{padding} : 25;
        my $padded_start = max(0, ($localised->{pair_start}-$padding));
        my $end = ($localised->{pair_start}+$localised->{pair_size}+$padding);

        # TODO refactor this
        #loop through all the insertions, and see if they are inside our new truncated range.
        for my $read ( values %{ $insertions } ) {
            while ( my ( $loc, $insertion ) = each %{ $read } ) {
                #its not inside the region we're viewing so delete it
                delete $read->{$loc} if $loc < $padded_start || $loc > $end;
            }
        }

        #loop through all the deletions, and see if they are inside our new truncated range.
        for my $read ( values %{ $deletions } ) {
            while ( my ( $loc, $deletion ) = each %{ $read } ) {
                #its not inside the region we're viewing so delete it
                delete $read->{$loc} if $loc < $padded_start || $loc > $end;
            }
        }

        #truncate all the seqs
        for my $s ( values %alignment_data ) {
            next if $s eq "" or $s eq "No alignment";

            #use split sequence to get crispr and surrounding region then merge back
            $s = join "", _split_sequence( $s, $localised->{pair_start}, $localised->{pair_size}, $padding );
        }
    }

    #split ref sequence into crispr and its surrounding sequence
    @alignment_data{qw(ref_start crispr_seq ref_end)}
        = _split_sequence( $seq, $localised->{pair_start}, $localised->{pair_size}, $padding );

    if ( !$self->fwd_read ) {
        $alignment_data{no_forward_read} = 1;
    }
    if ( !$self->rev_read ) {
        $alignment_data{no_reverse_read} = 1;
    }

    if ( $json->{forward_no_alignment} ) {
        $alignment_data{no_forward_alignment} = 1;
    }
    if ( $json->{reverse_no_alignment} ) {
        $alignment_data{no_reverse_alignment} = 1;
    }

    return ( \%alignment_data, $insertions, $deletions );
}
## use critic

#json is the analysis_data from crispr_es_qc_wells
sub get_localised_pair_coords {
    my ( $self, $json ) = @_;

    my $data = {
        pair_start => $json->{target_sequence_start} ? $self->crispr_start - $json->{target_sequence_start} : $self->crispr_start,
        pair_end   => $json->{target_sequence_end} ? $json->{target_sequence_end} - $self->crispr_end : $self->crispr_end,
        pair_size  => ($self->crispr_end - $self->crispr_start) + 1,
    };

    #$data->{pair_start} = 0 if $json->{target_sequence_start} > $pair->start;
    # Fix errors introduced by insertion symbol (Q) in ref sequence
    if ( my $ref = $json->{ref_sequence} ) {
        my $start_substr = substr( $ref, 0, $data->{pair_start} );
        my $start_Q_count = () = $start_substr =~ /Q/g;
        $data->{pair_start} += $start_Q_count;

        my $crispr_substr = substr( $ref, $data->{pair_start}, $data->{pair_size} );
        my $crispr_Q_count = () = $crispr_substr =~ /Q/g;
        $data->{pair_size} += $crispr_Q_count;
    }

    return $data;
}

#split a string containing a crispr into 3 parts
#no self because it's not needed
sub _split_sequence {
    my ( $seq, $crispr_start, $crispr_size, $padding ) = @_;

    return ( "" ) x 3 unless $seq;

    my $crispr_end = $crispr_start + $crispr_size;

    # if the crispr is not in the sequence return empty strings
    return ("") x 3 if $crispr_end <= 0;

    my $ref_end = "";
    my $start = 0; #default is beginning of string
    if ( $padding ) {
        $start = max(0, $crispr_start-$padding);
        #make sure we don't go over the end of the sequence
        #$last_size = min($padding, $last_size);

        #if the string is too short, add Xs to the right hand side to fill the space
        #this should really be done in the qc
        if ( length($seq) < $crispr_end+$padding ) {
            $seq .= "X" x (($crispr_end+$padding) - length($seq));
        }

        $ref_end = substr( $seq, $crispr_end, $padding );

        unless ( $ref_end ) {
            print $seq . "\n";
            print join ", ", $crispr_start, $crispr_end, $padding, "\n";
        }
    }
    else {
        #we want to the end of the string with no padding
        $ref_end = substr( $seq, $crispr_end );
    }

    #start can be 0 to do untruncated
    my $ref_start  =  substr( $seq, $start, $crispr_start-$start );
    #the actual crispr seq
    my $crispr_seq = substr( $seq, $crispr_start, $crispr_size );
    if ( $crispr_start <= 0 ) {
        $ref_start = '' if $crispr_start <= 0;
        $crispr_seq = substr( $seq, 0, $crispr_size + $crispr_start );
    }

    return $ref_start, $crispr_seq, $ref_end;
}

sub well_accepted_any_run {
    my $self = shift;

    my $accepted = $self->result_source->schema->resultset('CrisprEsQcWell')->find(
        {
            'well_id'  => $self->well->id,
            'accepted' => 't',
        }
    );

    return $accepted ? 1 : 0;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
