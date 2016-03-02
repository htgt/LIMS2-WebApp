package LIMS2::Model::Util::QCTemplates;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::QCTemplates::VERSION = '0.380';
}
## use critic

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_qc_template_from_wells
            qc_template_display_data
            eng_seq_data
            )
    ]
};

use LIMS2::Exception;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use Log::Log4perl qw( :easy );
use Hash::MoreUtils qw( slice_def );
use JSON;
use List::MoreUtils qw( uniq );
use Try::Tiny;

sub pspec_qc_template_from_wells {
    return {
        template_name => { validate => 'plate_name' },
        species       => { validate => 'existing_species' },
        wells         => { validate => 'hashref' },
    };
}

=head2 create_qc_template_wells

Create a qc_template plate along with its wells.
Insert eng_seq_params for each qc template well.

=cut
sub create_qc_template_from_wells {
	my ( $model, $params ) = @_;

	my $validated_params = $model->check_params( $params, pspec_qc_template_from_wells );

	my $existing = $model->retrieve_qc_templates({ name => $params->{template_name} });
	if ( @$existing ){
        LIMS2::Exception->throw( "QC template " . $validated_params->{template_name}
                . " already exists. Cannot use this plate name." );
	}
    DEBUG( "Attempting to create qc template plate: " . $validated_params->{template_name} );

	my $wells;
    for my $name ( keys %{ $validated_params->{wells} } ) {
        my $datum = $validated_params->{wells}->{$name};

        my $well_params = { slice_def( $datum, qw( plate_name well_name well_id cassette backbone) ) };

        # If we have a phase matched cassette group then handle it here
        if ( my $phase_match_group = $datum->{phase_matched_cassette} ) {
            if ( $datum->{cassette} ) {
                LIMS2::Exception->throw(
                    "A new cassette AND phase matched cassette have been provided for well $name");
            }
            TRACE "Attempting to fetch phase matched cassette for well $name";
            my $new_cassette = $model->retrieve_well_phase_matched_cassette(
                { slice_def( $datum, qw(plate_name well_name well_id phase_matched_cassette ) ) } );
            if ($new_cassette) {
                $well_params->{cassette} = $new_cassette;
            }
            else {
                LIMS2::Exception->throw("No suitable phase matched cassette found for well $name");
            }
            TRACE "Phase matched cassette: $new_cassette";
        }

        # Recombinase, if defined, must be an arrayref
        my $recombinase = $datum->{recombinase};
        if ( $recombinase and ref $recombinase eq ref [] ) {
            $well_params->{recombinase} = $recombinase;
        }
        elsif ($recombinase) {
            $well_params->{recombinase} = [$recombinase];
        }

        my ( $method, $source_well_id, $esb_params )
            = generate_well_eng_seq_params( $model, $well_params );

        $wells->{$name}->{eng_seq_id}     = $esb_params->{display_id};
        $wells->{$name}->{well_name}      = $validated_params->{template_name} . "_$name";
        $wells->{$name}->{eng_seq_method} = $method;
        $wells->{$name}->{eng_seq_params} = $esb_params;
        $wells->{$name}->{source_well_id} = $source_well_id;

        # We also need to store the overrides for each QC template well
        $wells->{$name}->{cassette}    = $well_params->{cassette};
        $wells->{$name}->{backbone}    = $well_params->{backbone};
        $wells->{$name}->{recombinase} = $well_params->{recombinase};
    }

    my $template = $model->find_or_create_qc_template(
        {   name    => $validated_params->{template_name},
            species => $validated_params->{species},
            wells   => $wells,
        }
    );
    INFO( 'Created qc template plate: ' . $validated_params->{template_name} );

    return $template;
}

=head2 qc_template_display_data

Generate data for display of qc_template plates.

=cut
sub qc_template_display_data {
    my ( $model, $template, $species ) = @_;

    my $has_crispr_data;
    my @well_info;
    foreach my $well ( $template->qc_template_wells ) {
        my %info;
        $info{id} = $well->id;
        $info{well_name} = $well->name;
        my $es_params = decode_json($well->qc_eng_seq->params);

        my $cassette_first;
        if ( my $source = $well->source_well ) {
            $info{source_plate} = $source->plate_name;
            $info{source_well} = $source->well_name;

            if ( my $design_id = $es_params->{design_id} ) {
                my $design = try{ $model->c_retrieve_design( { id => $design_id } ) };

                if ( $design ) {
                    design_data( $model, \%info, $design, $species );
                    $cassette_first = $design->cassette_first;
                }
            }

            if ( my $crispr_id = $es_params->{crispr_id} ) {
                my $crispr = try{ $model->retrieve_crispr( { id => $crispr_id } ) };

                if ( $crispr ) {
                    crispr_data( \%info, $crispr );
                    $has_crispr_data ||= 1;
                }
            }
        }

        eng_seq_data( $well, \%info, $cassette_first, $es_params );

        push @well_info, \%info;
    }

    my @sorted_well_data = sort { $a->{well_name} cmp $b->{well_name} } @well_info;

    return ( \@sorted_well_data, $has_crispr_data );
}

sub design_data {
    my ( $model, $info, $design, $species ) = @_;

    $info->{design_id} = $design->id;
    $info->{design_phase} = $design->phase;
    my @gene_ids = uniq map { $_->gene_id } $design->genes;

    my @gene_symbols;
    foreach my $gene_id ( @gene_ids ) {
        my $gene = $model->find_gene(
            { search_term => $gene_id, species =>  $species } );

        push @gene_symbols, $gene->{gene_symbol};
    }

    $info->{gene_ids} = join q{/}, @gene_ids;
    $info->{gene_symbols} = join q{/}, @gene_symbols;

    return;
}

sub crispr_data {
    my ( $info, $crispr ) = @_;

    $info->{crispr_id} = $crispr->id;
    $info->{crispr_seq} = $crispr->seq;

    return;
}

sub eng_seq_data {
    my ( $well, $info, $cassette_first, $es_params ) = @_;

    if ( $es_params->{insertion} ) {
        $info->{cassette} = $es_params->{insertion}->{name};
    }
    elsif ( $cassette_first && $es_params->{u_insertion} ) {
        $info->{cassette} = $es_params->{u_insertion}->{name};
    }
    elsif ( !$cassette_first && $es_params->{d_insertion} ) {
        $info->{cassette} = $es_params->{d_insertion}->{name};
    }
    else {
        $info->{cassette} = undef;
    }

    $info->{backbone} = $es_params->{backbone} ? $es_params->{backbone}->{name}
                                               : undef;

    $info->{recombinase} = $es_params->{recombinase} ? join ", ", @{$es_params->{recombinase}}
                                                     : undef;

    # Store as *_new the cassette, backbone and recombinases that
    # were specified for the qc template (rather than taken from source well)
    if (my $cassette = $well->qc_template_well_cassette) {
        $info->{cassette_new} = $cassette->cassette->name;
    }
    if (my $backbone = $well->qc_template_well_backbone) {
        $info->{backbone_new} = $backbone->backbone->name;
    }
    if (my @template_recombinases = $well->qc_template_well_recombinases->all) {
        # eng_seq_params recombinase is a list of well recombinases + template recmobinase
        # remove the template recombinases to generate the list of original well recombinases
        if($es_params->{recombinase}){
            my @eng_seq_recombinases = @{ $es_params->{recombinase} };
            my @orig_recombinases;
            foreach my $recombinase (@eng_seq_recombinases){
                push @orig_recombinases, $recombinase unless grep { $recombinase eq lc($_) }
                                                             map { $_->id }
                                                             @template_recombinases ;
            }
            # Store list of orig recombinases
            $info->{recombinase} = @orig_recombinases ? join ", ", @orig_recombinases : undef;
        }
        # Store list of template recombinases
        $info->{recombinase_new} = join ", ", map { $_->recombinase_id } @template_recombinases;
    }

    return;
}

1;

__END__
