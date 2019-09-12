package LIMS2::Model::Util::CrispressoSubmission;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw(
        get_eps_for_plate
        get_eps_to_miseqs_map
        get_parents_to_miseqs_map
        get_well_map
    ) ]
};
use Log::Log4perl qw( :easy );
use LIMS2::Exception;
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
        my @miseqs = map { $wells{$_}->{index} } @{ $store->{miseqs} };
        my $crispr = $row->process->process_crispr->crispr;
        my $exp = $model->schema->resultset('Experiment')->find({
            crispr_id => $crispr->id,
            design_id => $design->id,
        });
        if ($exp) {
            $exp = $exp->id;
        }

        my %values = (
            name        =>
                join( '_', $plates{ $wells{$ep}->{plate} }, $wells{$ep}->{name}, $gene->{gene_symbol} ),
            crispr      => $crispr->seq,
            amplicon    => $amplicon,
            strand      => q/+/,
            gene        => $gene->{gene_symbol},
            min_index   => min(@miseqs),
            max_index   => max(@miseqs),
            exp_id      => $exp,
        );

        if ($design->hdr_amplicon) {
            $values{hdr} = $design->hdr_amplicon;
        }

        foreach my $key ( keys %values ) {
            $store->{$key} = $values{$key};
        }
    }
    return $eps;
}

sub get_well_map {
    my ( $model, $eps, $miseq_only ) = @_;
    my @miseqs = map { @{ $_->{miseqs} } } values %{$eps};
    my %wells = map { $_ => 1 } @miseqs, keys %{$eps};
    my $indices = wells_generator(1);

    my @wells = keys %wells;
    if ($miseq_only) {
        @wells = @miseqs;
    }
    return map {
        $_->id => {
            id    => $_->id,
            plate => $_->plate_id,
            name  => $_->name,
            index => $indices->{ $_->name },
          }
      } $model->schema->resultset('Well')
      ->search( { id => { -in => [ @wells ] } } );
}

sub get_eps_to_miseqs_map {
    my ( $model, $plate_id ) = @_;
    my $result = $model->get_ancestors_by_plate_id($plate_id);
    my %eps;
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

sub get_parents_to_miseqs_map {
    my ( $model, $plate_id, $miseq_name ) = @_;

    my $miseq_well_query = $model->schema->resultset('Well')->search ({
        'me.plate_id'     => $plate_id,
    },{
        prefetch => {
            'process_input_wells' => {
                'process' => {
                    'process_output_wells' => 'well'
                }
            }
        },
    });

    my $parents;
    while (my $parent_well = $miseq_well_query->next) {
        $parents = _consolidate_well_query($parents, $parent_well, $miseq_name);
    }

    return $parents;
}

sub _consolidate_well_query {
    my ($parents, $parent_well, $miseq_name) = @_;

    my @process_inputs = $parent_well->process_input_wells;
    my @process_outputs = map { $_->process->process_output_wells } @process_inputs;
    foreach my $miseq_output (@process_outputs) {
        my $plate_name = $miseq_output->well->plate->name;
        if ($plate_name eq $miseq_name) {
            my $pid = $parent_well->id;
            if ( not exists $parents->{$pid} ) {
                $parents->{$pid} = {
                    process => $miseq_output->process_id,
                    parent  => $pid,
                    miseqs  => []
                };
            }
            push @{ $parents->{$pid}->{miseqs} }, $miseq_output->well->id;
        }
    }

    return $parents;
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