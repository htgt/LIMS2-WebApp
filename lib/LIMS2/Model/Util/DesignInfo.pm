package LIMS2::Model::Util::DesignInfo;

use Moose;
use LIMS2::Exception;
use namespace::autoclean;

use List::MoreUtils qw( uniq all );

has design => (
    is       => 'ro',
    isa      => 'LIMS2::Model::Schema::Result::Design',
    required => 1,
);

has type => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_type {
    return shift->design->design_type_id;
}

has default_assembly => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_default_assembly {
    return shift->design->species->default_assembly->assembly_id;
}

has oligos => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

has chr_strand => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1
);

has chr_name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has [
    qw( target_region_start target_region_end )
] => (
    is         => 'ro',
    isa        => 'Maybe[Int]',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_target_region_start {
    my $self = shift;
    
    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U5}{end};
        }
        else {
            return $self->oligos->{D3}{end};
        }   
    }
      
    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{U3}{start};
        }
        else {
            return $self->oligos->{D5}{start}
        }   
    }
}

sub _build_target_region_end {
    my $self = shift;
    
    if ( $self->type eq 'deletion' || $self->type eq 'insertion' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D3}{start};
        }
        else {
            return $self->oligos->{U5}{start}
        }   
    }
    
    if ( $self->type eq 'conditional' || $self->type eq 'artificial-intron' ) {
        if ( $self->chr_strand == 1 ) {
            return $self->oligos->{D5}{end}
        }
        else {
            return $self->oligos->{U3}{end};
        }   
    }
}

sub _build_chr_strand {
    my $self = shift;

    my @strands = uniq map { $_->{strand} } values %{ $self->oligos }; 
    LIMS2::Exception->throw(
        'Design ' . $self->design->id . ' oligos have inconsistent strands'
    ) unless @strands == 1;

    return shift @strands;
}

sub _build_chr_name {
    my $self = shift;

    my @chr_names = uniq map { $_->{chromosome} } values %{ $self->oligos }; 
    LIMS2::Exception->throw(
        'Design ' . $self->design->id . ' oligos have inconsistent chromosomes'
    ) unless @chr_names == 1;

    return shift @chr_names;
}

# Build up oligos with information from current assembly
sub _build_oligos {
    my $self = shift;
    my %oligos;

    for my $oligo ( $self->design->oligos ) {
        my %oligo_data;
        my $locus = $oligo->loci->find( { assembly_id => $self->default_assembly } ); 

        %oligo_data = (
            start      => $locus->chr_start,
            end        => $locus->chr_end,
            chromosome => $locus->chr->name,
            strand     => $locus->chr_strand,
        ) if $locus;
        $oligo_data{seq} = $oligo->seq;

        $oligos{ $oligo->design_oligo_type_id } = \%oligo_data;
    }

    return \%oligos;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
