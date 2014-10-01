package LIMS2::Report::EPSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::EPSummary::VERSION = '0.250';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

override _build_name => sub {
    return 'Electroporation Summary';
};

override _build_columns => sub {
    return [
        "Gene",
        "Project",
        "Plate_Well ID",
        "FEPD Targeted Clones",
        "SEPD Targeted Clone",
        "1st allele targeting design ID",
        "1st allele targeting drug resistance",
        "1st allele targeting promotor",
        "1st allele targeting vector plate",
        "FEPD Number",
        "2nd allele targeting design ID",
        "2nd allele targeting drug resistance",
        "2nd allele targeting promotor",
        "2nd allele targeting vector plate",
        "SEPD Number",
    ];
};

sub build_summary_data {
    my $self = shift;
    my $sponsor = shift(@_);
    my %report_data;

    my @projects = $self->model->schema->resultset('Project')->search({
        sponsor_id     => $sponsor,
    },{
        select => [ 'gene_id' ],
    });

    # Loop through genes
    foreach my $project (@projects) {

        my @gene_designs = $self->model->schema->resultset('GeneDesign')->search({
            gene_id => $project->gene_id
        },{
            select => [ 'design_id' ],
        });

        # Loop through designs
        foreach my $gene_design (@gene_designs) {

            my @design_rows = $self->model->schema->resultset('Summary')->search({
                design_id => $gene_design->design_id,
                final_pick_cassette_cre => '0',
                -or => [
                    ep_plate_name => { '!=', undef },
                     {
                         sep_plate_name => { '!=', undef }
                     },
                ],
            });

            my (%current_well, %fepd_plates, %sepd_plates, %fepd_wells, %sepd_wells);

            # This is the actual summaries table rows
            foreach my $data (@design_rows) {

                my $plate = $data->ep_plate_name // '';
                my $well = $data->ep_well_name // '';
                my $EP_well_name = $plate.'_'.$well;
                if (defined $EP_well_name && !exists $report_data{$EP_well_name}) {
                    $report_data{$EP_well_name} = \%current_well unless ($EP_well_name eq '_');
                };

                # print "# current row: $EP_well_name \n";
                my $gene = $data->design_gene_symbol;
                $current_well{gene} = $gene;
                $current_well{project} = $sponsor;

                # FEPD Targeted Clones
                if ($data->ep_pick_plate_name) {
                    my $fepd_well_name = $data->ep_pick_plate_name.'_'.$data->ep_pick_well_name;
                    my $fepd_plate = $data->ep_pick_plate_name;
                    $fepd_wells{$fepd_well_name} = $data->ep_pick_well_accepted;
                    $fepd_plates{$fepd_plate} = 1;
                }

                # SEPD Targeted Clones
                if ($data->sep_pick_plate_name) {
                    my $sepd_well_name = $data->sep_pick_plate_name.'_'.$data->sep_pick_well_name;
                    my $sepd_plate = $data->sep_pick_plate_name;
                    $sepd_wells{$sepd_well_name} = $data->sep_pick_well_accepted;
                    $sepd_plates{$sepd_plate} = 1;
                }

                my $allele_number = ($data->ep_well_name) ? 1 : 2;


                $current_well{$allele_number."_design_id"} = $data->design_id;
                $current_well{$allele_number."_drug_resistance"} = $data->final_pick_cassette_resistance;
                if (!$data->final_pick_cassette_promoter) {
                    $current_well{$allele_number."_targeting_promoter"} = "Promoterless";
                }
                else {
                    $current_well{$allele_number."_targeting_promoter"} = $data->final_pick_cassette_name;
                }
                $current_well{$allele_number."_targeting_vector_plate"} = $data->final_pick_plate_name;

            }
            $current_well{'fepd_number'} = join ":", keys %fepd_plates;
            $current_well{'fepd_targeted_clones'} = scalar grep { $_ } values %fepd_wells;
            $current_well{'sepd_number'} = join ":", keys %sepd_plates;
            $current_well{'sepd_targeted_clones'} =  scalar grep { $_ } values %sepd_wells;
        }
    }

    my @output;

    while ( my ($key, $value) = each %report_data ) {

        push(@output, [
            $value->{'gene'},
            $value->{'project'},
            $key,
            $value->{'fepd_targeted_clones'},
            $value->{'sepd_targeted_clones'},
            $value->{'1_design_id'},
            $value->{'1_drug_resistance'},
            $value->{'1_targeting_promoter'},
            $value->{'1_targeting_vector_plate'},
            $value->{'fepd_number'},
            $value->{'2_design_id'},
            $value->{'2_drug_resistance'},
            $value->{'2_targeting_promoter'},
            $value->{'2_targeting_vector_plate'},
            $value->{'sepd_number'},
        ] );
    }

    return \@output;

}




override iterator => sub {
    my ( $self ) = @_;

    my $summary_data;
    my @sponsors;

    if ( $self->sponsor ne 'All' ) {
        @sponsors = ($self->sponsor);
    }
    else {
        if ($self->species eq 'Mouse') {
                @sponsors = ('Core', 'Syboss', 'Pathogens');
        } else {
                @sponsors = ('Adams', 'Human-Core', 'Mutation', 'Pathogen', 'Skarnes', 'Transfacs');
        }
    }

    foreach my $sponsor (@sponsors) {
    	my $sponsor_data = $self->build_summary_data($sponsor);
    	push ( @{$summary_data},  @{$sponsor_data});
	}

    return Iterator::Simple::iter( $summary_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__
