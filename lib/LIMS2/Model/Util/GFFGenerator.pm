package LIMS2::Model::Util::GFFGenerator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::GFFGenerator::VERSION = '0.531';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::GFFGenerator

=head1 DESCRIPTION

Module to generate GFF format line(s) to be displayed in genoverse

The following objects can be converted to gff:
Design
GenotypingPrimer
Crispr/Pair/Group
CrisprPrimer

=cut

use Moose;
use Data::Dumper;

with 'MooseX::Log::Log4perl';

sub crispr_colour {
    my $type = shift;

    my %colours = (
        single => '#45A825', # green
        left   => '#45A825', # green
        right  => '#52CCCC', # bright blue
        pam    => '#1A8599', # blue
        primer => '#45A825', # green
        SF1    => '#80aaff', # blue
        SR1    => '#80aaff',
        PF1    => '#ffb366', # orange
        PR1    => '#ffb366',
        PF2    => '#ffd11a', # yellow
        PR2    => '#ffd11a',
    );

    return $colours{ $type } // '#000000';
}

sub generic_colour {
    my $oligo_type_id = shift;
    # TODO: Why not get this from the database?
    #
    my %colours = (
        '5F' => '#68D310',
        '5R' => '#68D310',
        'EF' => '#589BDD',
        'ER' => '#589BDD',
        '3F' => '#BF249B',
        '3R' => '#BF249B',
        'D3' => '#68D310',
        'D5' => '#68D310',
        'G3' => '#589BDD',
        'G5' => '#589BDD',
        'U3' => '#BF249B',
        'U5' => '#BF249B',
        'N' => '#18D6CD',
        'f5F' => '#68D310',
        'f3R' => '#BF249B',
        'EXF' => '#68D310',
        'EXR' => '#68D310',
        'INF' => '#589BDD',
        'INR' => '#589BDD',
        # These are for design oligo search regions:
        '5R_EF' => '#68D310',
        'ER_3F' => '#BF249B',
        'target' => '#000000',
        # These are the genotyping primers
        'GF1' => '#660066', # dark purple
        'GR1' => '#660066',
        'GF2' => '#b366ff', # pale purple
        'GR2' => '#b366ff',
    );
    return $colours{ $oligo_type_id } // '#000000';
}

sub generate_gff{
	my ($self, $object) = @_;

    my $method_for = {
        'LIMS2::Model::Schema::Result::Design' => \&_design_gff,
        'LIMS2::Model::Schema::Result::Crispr' => \&_crispr_gff,
        'LIMS2::Model::Schema::Result::CrisprPair' => \&_crispr_pair_gff,
        'LIMS2::Model::Schema::Result::CrisprGroup' => \&_crispr_group_gff,
        'LIMS2::Model::Schema::Result::CrisprLocus' => \&_crispr_locus_gff,
        'LIMS2::Model::Schema::Result::CrisprBrowserPairs' => \&_crispr_browser_pair_gff,
        'LIMS2::Model::Schema::Result::CrisprPrimer' => \&_crispr_primer_gff,
        'LIMS2::Model::Schema::Result::GenotypingPrimer' => \&_genotyping_primer_gff,
    };
    my $object_class = ref($object);
    my $method = $method_for->{$object_class}
        or $self->log->logdie("No GFF conversion method found for $object_class");

    $self->log->debug("Generating GFF for $object_class");
	my @gff_lines;
    push @gff_lines, $method_for->{ ref($object) }->($self, $object);
    return @gff_lines;
}

sub _design_gff{
    my ($self, $design) = @_;

    my @gff;
    my $parent_id = 'D_' . $design->id;
    my $parent_params = {
        'seqid'  => $design->chr_name,
        'source' => 'LIMS2',
        'type'   =>  $design->design_type_id,
        'start'  => $design->start,
        'end'    => $design->end,
        'score'  => '.',
        'strand' => ( $design->chr_strand eq '-1' ) ? '-' : '+',
        'phase' => '.',
        'attributes' => {
            'ID'   => $parent_id,
            'Name' => $parent_id,
        },
    };

    push @gff, $self->gff_from_hash($parent_params);

    foreach my $oligo ($design->oligos){
        my $locus = $oligo->current_locus;
        my $type = $oligo->design_oligo_type_id;
        my $oligo_params = {
            seqid => $design->chr_name,
            source => 'LIMS2',
            score => '.',
            phase => '.',
            type  => 'CDS',
            start => $locus->chr_start,
            end   => $locus->chr_end,
            strand => $locus->chr_strand,
            attributes => {
                ID     => $type,
                Parent => $parent_id,
                Name   => $type,
                color  => generic_colour($type),
            },
        };
        push @gff, $self->gff_from_hash($oligo_params);
    }
    return @gff;
}

sub _genotyping_primer_gff{
    my ($self, $primer) = @_;

    my $locus = $primer->current_locus;

    my $start = $locus->chr_start;
    my $end = $locus->chr_end;
    my $chr = $locus->chr->name;
    my $name = $primer->genotyping_primer_type_id;

    my @gff;
    my $parent_id = 'GP_'.$primer->id;
    my $params = {
        seqid => $chr,
        source => 'LIMS2',
        score => '.',
        phase => '.',
        type  => 'Genotyping Primer',
        start => $start < $end ? $start : $end,
        end   => $end > $start ? $end : $start,
        strand => $locus->chr_strand == 1 ? "+" : "-",
        attributes => {
            Name => $name,
            ID => $parent_id,
            color => generic_colour($name),
        },
    };
    push @gff, $self->gff_from_hash($params);

    # Add second GFF feature which is exon-like so
    # that the primer is displayed as a solid block
    $params->{type} = "CDS";
    $params->{attributes} = {
        Name => $name,
        ID => 'GP_CDS_'.$primer->id,
        color => generic_colour($name),
        Parent =>  $parent_id,
    };
    push @gff, $self->gff_from_hash($params);

    return @gff;
}

sub _crispr_gff{
    my ($self, $crispr) = @_;

    return $self->_crispr_locus_gff($crispr->current_locus);
}

sub _crispr_pair_gff{
    my ($self,$pair) = @_;

    my @gff;
    push @gff, $self->_crispr_locus_gff($pair->left_crispr->current_locus);
    push @gff, $self->_crispr_locus_gff($pair->right_crispr->current_locus);
    return @gff;
}

sub _crispr_group_gff{
    my ($self, $group) = @_;

    my @gff;
    foreach my $crispr ($group->crisprs){
        push @gff, $self->_crispr_locus_gff($crispr->current_locus);
    }
    return @gff;
}

sub _crispr_locus_gff{
	my ($self, $crispr) = @_;

    my @gff;
    my $id = 'C_' . $crispr->crispr_id;
    my $params = {
        'seqid'      => $crispr->chr->name,
        'source'     => 'LIMS2',
        'type'       => 'Crispr',
        'start'      => $crispr->chr_start,
        'end'        => $crispr->chr_end,
        'score'      => '.',
        'strand'     => $crispr->chr_strand eq '-1' ? '-' : '+' ,
        'phase'      => '.',
        'attributes' => {
        	ID   => $id,
            Name => 'LIMS2' . '-' . $crispr->crispr_id,
            seq  => $crispr->crispr->seq,
            pam_right => ($crispr->crispr->pam_right // 'N/A'),
            wge_ref   => ($crispr->crispr->wge_crispr_id // 'N/A'),
        }
    };

    push @gff, $self->gff_from_hash($params);

    my $crispr_display_info = {
        id => $crispr->crispr_id,
        chr_start => $crispr->chr_start,
        chr_end => $crispr->chr_end,
        pam_right => $crispr->crispr->pam_right,
        colour => '#45A825', # greenish
    };

    push @gff, $self->_make_crispr_and_pam_cds($crispr_display_info, $params, $id);
    return @gff;
}

sub _crispr_browser_pair_gff{
    my ($self, $crispr_r) = @_;

    my @gff;

    my $pair_id = $crispr_r->pair_id;
    my $crispr_format_hash = {
        'seqid' => $crispr_r->chr_name,
        'source' => 'LIMS2',
        'type' => 'crispr_pair',
        'start' => $crispr_r->left_crispr_start,
        'end' => $crispr_r->right_crispr_end,
        'score' => '.',
        'strand' => '+' ,
#                'strand' => '.',
        'phase' => '.',
        'attributes' => 'ID='
            . $pair_id . ';'
            . 'Name=' . 'LIMS2' . '-' . $pair_id
    };
    my $crispr_pair_parent = $self->gff_from_hash( $crispr_format_hash );
    push @gff, $crispr_pair_parent;

    my $crispr_display_info = {
        left => {
            id    => $crispr_r->left_crispr_id,
            chr_start => $crispr_r->left_crispr_start,
            chr_end   => $crispr_r->left_crispr_end,
            pam_right => $crispr_r->left_crispr_pam_right,
            colour => crispr_colour('left'),
        },
        right => {
            id    => $crispr_r->right_crispr_id,
            chr_start => $crispr_r->right_crispr_start,
            chr_end   => $crispr_r->right_crispr_end,
            pam_right => $crispr_r->right_crispr_pam_right,
            colour => crispr_colour('right'),
        }
    };

    foreach my $side ( qw(left right) ){
        my $crispr = $crispr_display_info->{$side};
        push @gff, $self->_make_crispr_and_pam_cds($crispr, $crispr_format_hash, $pair_id);
    }

    return @gff;
}



sub _crispr_primer_gff{
    my ($self, $primer) = @_;

    my $start = $primer->start;
    my $end = $primer->end;
    my $name = $primer->primer_name->primer_name;

    my @gff;
    my $parent_id = 'CP_'.$primer->id;
    my $params = {
        seqid => $primer->chr_name,
        source => 'LIMS2',
        score => '.',
        phase => '.',
        type  => 'Crispr Primer',
        start => $start < $end ? $start : $end,
        end   => $end > $start ? $end : $start,
        strand => $primer->chr_strand == 1 ? "+" : "-",
        attributes => {
            Name => $name,
            ID => $parent_id,
            color => crispr_colour($name),
        },
    };
    push @gff, $self->gff_from_hash($params);

    # Add second GFF feature which is exon-like so
    # that the primer is displayed as a solid block
    $params->{type} = "CDS";
    $params->{attributes} = {
        Name => $name,
        ID => 'CP_CDS_'.$primer->id,
        color => crispr_colour($name),
        Parent =>  $parent_id,
    };
    push @gff, $self->gff_from_hash($params);

    return @gff;
}

sub _make_crispr_and_pam_cds{
    my ($self, $crispr_display_info, $crispr_format_hash, $parent_id) = @_;

    # crispr display info must contain keys:
    # id, chr_start, chr_end, pam_right, colour

    my $crispr = $crispr_display_info;
    if(defined $crispr->{pam_right}){
        my ($pam_start, $pam_end);
        if($crispr->{pam_right}){
            $crispr_format_hash->{'start'} = $crispr->{chr_start};
            $crispr_format_hash->{'end'} = $crispr->{chr_end} - 2;
            $pam_start =  $crispr->{chr_end} - 2;
            $pam_end = $crispr->{chr_end};
        }
        else{
            $crispr_format_hash->{'start'} = $crispr->{chr_start} + 2;
            $crispr_format_hash->{'end'} = $crispr->{chr_end};
            $pam_start = $crispr->{chr_start};
            $pam_end = $crispr->{chr_start} + 2;
        }

        # This is the crispr without PAM
        $crispr_format_hash->{'type'} = 'CDS';
        $crispr_format_hash->{'attributes'} = 'ID='
            . 'Crispr_' . $crispr->{id} . ';'
            . 'Parent=' . $parent_id . ';'
            . 'Name=LIMS2-' . $crispr->{id} . ';'
            . 'color=' .$crispr->{colour};
        my $crispr_datum = $self->gff_from_hash( $crispr_format_hash );

        # This is the PAM
        $crispr_format_hash->{start} = $pam_start;
        $crispr_format_hash->{end} = $pam_end;
        $crispr_format_hash->{'attributes'} = 'ID='
                . 'PAM_' . $crispr->{id} . ';'
                . 'Parent=' . $parent_id . ';'
                . 'Name=LIMS2-' . $crispr->{id} . ';'
                . 'color=' . crispr_colour('pam');
        my $pam_child_datum = $self->gff_from_hash( $crispr_format_hash );

        return ($crispr_datum, $pam_child_datum);
    }
    else{
        # We don't have pam right flag so just make the crispr cds
        $crispr_format_hash->{start} = $crispr->{chr_start};
        $crispr_format_hash->{end} = $crispr->{chr_end};
        $crispr_format_hash->{'type'} = 'CDS';
        $crispr_format_hash->{'attributes'} = 'ID='
            . $crispr->{id} . ';'
            . 'Parent=' . $parent_id . ';'
            . 'Name=' . $crispr->{id} . ';'
            . 'color=' .$crispr->{colour};
        my $crispr_datum = $self->gff_from_hash( $crispr_format_hash );
        return $crispr_datum;
    }

    return;
}

# Attributes can be provided either as a string in the format Key1=Value1;Key2=Value2
# or hashref { Key1 => Value1 } which will be converted to string
sub gff_from_hash{
    my ($self, $params) = @_;

    my @values;

    if( ref($params->{attributes}) eq ref({}) ){
        my @att_strings;
    	foreach my $key (keys %{ $params->{attributes} }){
            push @att_strings, $key."=".$params->{attributes}->{$key};
    	}
    	$params->{attributes} = join ";", @att_strings;
    }

    push @values, @$params{qw/
        seqid
        source
        type
        start
        end
        score
        strand
        phase
        attributes
        /};

    my $line= join "\t", @values;
    return $line;
}
1;
