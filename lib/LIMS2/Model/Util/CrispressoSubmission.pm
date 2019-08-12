package LIMS2::Model::Util::CrispressoSubmission;

use strict;
use warnings FATAL => 'all';
use Sub::Exporter -setup => {
    exports => [
        qw(
              get_eps_for_plate
          )
    ]
};

use Log::Log4perl qw( :easy );
use LIMS2::Exception;
use Moose;
use namespace::autoclean;
use Carp;
use LIMS2::Model::Util::Miseq qw/wells_generator/;
use List::Util qw/min max/;
use Text::CSV;

sub get_eps_for_plate {
    my ( $model, $plate ) = @_;
    my $eps = get_eps_to_miseqs_map( $model, $plate );
    my %wells = get_well_map( $model, $eps );
    my %plates = get_plate_map( $model, \%wells );

    my @data = $model->schema->resultset('ProcessOutputWell')->search(
        {
            well_id                       => { -in => [ keys %{$eps} ] },
            'oligos.design_oligo_type_id' => { -in => [qw/INF INR/] },
        },
        {
            prefetch => [
                {
                    process => [
                        {
                            process_design => {
                                design => [
                                    qw/genes hdr_templates/,
                                    {
                                        oligos =>
                                          { loci => [qw/assembly chr/] },
                                    },
                                ]
                            }
                        },
                        { process_crispr => 'crispr' },
                    ]
                },
            ]
        }
    );
$DB::single=1;
    foreach my $row (@data) {
        my $design = $row->process->process_design->design;
        my %oligos = map {
            $_->design_oligo_type_id =>
              { locus => $_->loci->first->as_hash, seq => $_->seq, }
        } $design->oligos;
        my $amplicon = get_oligo_seq( $design, %oligos ) // q/?/;
        my $ep       = $row->well_id;
        my $store    = $eps->{$ep};
        check_matches(
            $store,
            design  => $design->id,
            ep      => $ep,
            process => $row->process->id,
        );
        my $gene = $model->retrieve_gene(
            {
                species => 'Human',
                search_term =>
                  single( map { $_->gene_id } $design->genes->all ),
            }
        );
        my @miseqs = map { $wells{$_}->{index} + 1 } @{ $store->{miseqs} };
        my %values = (
            name =>
              join( '_', $plates{ $wells{$ep}->{plate} }, $wells{$ep}->{name}, $gene->{gene_symbol} ),
            crispr   => $row->process->process_crispr->crispr->seq,
            amplicon => $amplicon,
            strand   => q/+/,
            gene     => $gene->{gene_symbol},
            hdr => single( map { $_->template } $design->hdr_templates->all ),
            min_index => min(@miseqs),
            max_index => max(@miseqs),
            exp_id    => ,
            parent_id => ,
        );

        foreach my $key ( keys %values ) {
            $store->{$key} = $values{$key};
        }
    }
    return $eps;
}

sub get_well_map {
    my ( $model, $eps ) = @_;
    my @miseqs = map { @{ $_->{miseqs} } } values %{$eps};
    my %wells = map { $_ => 1 } @miseqs, keys %{$eps};
    my $indices = wells_generator(1);
    return map {
        $_->id => {
            id    => $_->id,
            plate => $_->plate_id,
            name  => $_->name,
            index => $indices->{ $_->name },
          }
      } $model->schema->resultset('Well')
      ->search( { id => { -in => [ keys %wells ] } } );
}

sub get_eps_to_miseqs_map {
    my ( $model, $plate_id ) = @_;
    my $result = $model->get_ancestors_by_plate_id($plate_id);
    my %eps;
$DB::single=1;
    foreach my $row ( @{$result} ) {
        my ( $pid, $iwid, $ep, $design, $miseq, $path ) = @{$row};
        if ( not exists $eps{$ep} ) {
            $eps{$ep} = {
                process => $pid,
                ep      => $ep,
                design  => $design,
                miseqs  => []
            };
        }
        push @{ $eps{$ep}->{miseqs} }, $miseq;
    }
    return \%eps;
}

sub get_plate_map {
    my ( $model, $wells ) = @_;
    my %plate_ids = map { $_ => 1 } map { $_->{plate} } values %{$wells};
    return
      map { $_->id => $_->name }
      $model->schema->resultset('Plate')
      ->search( { id => { -in => [ keys %plate_ids ] } } );
}

sub get_oligo_seq {
    my ( $design, %oligos ) = @_;
    return if ( not exists $oligos{INF} ) || ( not exists $oligos{INR} );
    my ( $infl, $inrl ) = map { $oligos{$_}->{locus} } qw/INF INR/;
    return if $infl->{chr_name} ne $inrl->{chr_name};
    my $distance = $inrl->{chr_start} - $infl->{chr_end};
    return if $distance < 0 || $distance > 500;
    return $design->_fetch_region_coords( $oligos{INF}, $oligos{INR} );
}

sub check_matches {
    my ( $store, %expected ) = @_;
    foreach my $key ( keys %expected ) {
        croak "$key $expected{$key} != $store->{$key}"
          if $store->{$key} != $expected{$key};
    }
    return;
}

sub single {
    my @data = @_;
    croak 'Expected one but got many' if scalar(@data) > 1;
    return $data[0];
}

1;