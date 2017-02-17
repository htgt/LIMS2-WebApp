package LIMS2::Report::CrisprEPWellSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPWellSummary::VERSION = '0.447';
}
## use critic


use Moose;
use namespace::autoclean;
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick ep_pick_is_het);
use Try::Tiny;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

override _build_name => sub {
    return 'Gene Electroporation Well Summary';
};

override _build_columns => sub {
    return [
        'Gene ID',
        'Gene symbol',
        'Chromosome',
        'EP well',
        'EP timestamp',
        'To report',
        'Cell line',
        'Design ID',
        'Design well',
        'Method',
        'DNA template',
        'Assembly well',
        'Final pick vector',
        'CRISPR entity id',
        'CRISPR entity type',
        '# colonies',
        'iPSC colonies picked',
        'Total genotyped clones',
        '# frame-shift clones',
        '# in-frame clones',
        '# wt clones',
        '# mosaic clones',
        '# no-call clones',
        'Het clones',
        'Distributable clones',
    ];
};

has concat_str => (
    is      => 'rw',
    isa     => 'Str',
    default => ', ',
);

has any_accepted_attribute => (
    is      => 'rw',
    isa     => 'Str',
    default => "{ '=', [ 't', 'f', undef ] },",
);

has only_accepted_attribute => (
    is      => 'rw',
    isa     => 'Str',
    default => 't',
);


override iterator => sub {
    my ( $self ) = @_;

    my $summary_rs = $self->model->schema->resultset("Summary")->search(
        {
            'crispr_ep_well_id' => { '!=', undef },
            'design_species_id' => $self->species,
        }
    );

    my @crispr_ep_wells = $summary_rs->search(
        { }, {
            select => [ qw/design_type design_plate_name design_well_name dna_template crispr_ep_plate_name crispr_ep_well_id crispr_ep_well_name crispr_ep_well_created_ts design_id design_gene_id design_gene_symbol assembly_plate_name assembly_well_name assembly_well_id final_pick_plate_name final_pick_well_name crispr_ep_well_cell_line to_report/ ],
            order_by => 'crispr_ep_well_id',
            distinct => 1
        }
    );

    my $species = $self->model->schema->resultset('Species')->find({ id => $self->species});
    my $assembly_id = $species->default_assembly->assembly_id;


    return Iterator::Simple::iter sub {

        my $crispr_ep_well = shift @crispr_ep_wells
            or return;

            #Basic and CRISPR_EP info

            my $ep_well = $crispr_ep_well->crispr_ep_plate_name . '_' . $crispr_ep_well->crispr_ep_well_name;

            my $ep_well_ts = $crispr_ep_well->crispr_ep_well_created_ts;

            my $gene_symbol = $crispr_ep_well->design_gene_symbol;

            my $gene_id = $crispr_ep_well->design_gene_id;

            my $design_id = $crispr_ep_well->design_id;

            my $cell_line = $crispr_ep_well->crispr_ep_well_cell_line;

            my $design_type = $crispr_ep_well->design_type;

            my $design_well = $crispr_ep_well->design_plate_name . '_' . $crispr_ep_well->design_well_name;

            my $dna_template = '';
            try {
                $dna_template = $crispr_ep_well->dna_template->id;
            };

            my $assembly = $crispr_ep_well->assembly_plate_name . '_' . $crispr_ep_well->assembly_well_name;

            my $final_pick = $crispr_ep_well->final_pick_plate_name . '_' . $crispr_ep_well->final_pick_well_name // '';

            my $to_report = 'no';
            if ($crispr_ep_well->to_report) {
                $to_report = 'yes';
            }

            my $total_colonies = '';
            try {
                $total_colonies = $self->model->schema->resultset('WellColonyCount')->search({
                    well_id => $crispr_ep_well->crispr_ep_well_id,
                    colony_count_type_id => 'total_colonies',
                } )->single->colony_count;
            };

            my $crispr_id = '';
            my $crispr_type = '';
            try {
                my $assembly_well = $self->model->retrieve_well({ id => $crispr_ep_well->assembly_well_id });
                $crispr_id = $assembly_well->crispr_entity->id;
                $crispr_type = $assembly_well->crispr_entity->id_column_name;
            };

            # Get chromosome number from design
            my $design = $self->model->schema->resultset('Design')->find({
                id => $crispr_ep_well->design_id,
            });
            my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
            my $chromosome = $design_oligo_locus->chr->name;

            # EP_PICK wells
            my @ep_pick = $summary_rs->search(
                {
                    ep_pick_plate_name => { '!=', undef },
                    crispr_ep_well_id => $crispr_ep_well->crispr_ep_well_id,
                    to_report => 't',
                },{
                    columns => [ qw/ep_pick_plate_name ep_pick_well_name ep_pick_well_accepted ep_pick_well_id/ ],
                    distinct => 1
                }
            );

            my $ep_pick_count = scalar @ep_pick;

            my %damage_counts;
            $damage_counts{'frameshift'} = 0;
            $damage_counts{'in-frame'} = 0;
            $damage_counts{'wild_type'} = 0;
            $damage_counts{'mosaic'} = 0;
            $damage_counts{'no-call'} = 0;
            my $het_count;

            ## no critic(ProhibitDeepNests)
            foreach my $ep_pick (@ep_pick) {
                my $damage_call = crispr_damage_type_for_ep_pick($self->model,$ep_pick->ep_pick_well_id);

                if ($damage_call) {
                    $damage_counts{$damage_call}++;
                }
                else {
                    $damage_call = '';
                }

                my $is_het = ep_pick_is_het($self->model, $ep_pick->ep_pick_well_id, $chromosome, $damage_call);

                if ( defined $is_het) {
                    $het_count += $is_het;
                }

            }
            ## use critic

            $damage_counts{'frameshift'} += $damage_counts{'splice_acceptor'} unless (!$damage_counts{'splice_acceptor'});
            my $ep_pick_pass_count = $damage_counts{'wild_type'} + $damage_counts{'in-frame'} + $damage_counts{'frameshift'} + $damage_counts{'mosaic'};
            if (!defined $het_count) {
                $het_count = '';
            }

            # PIQ wells
            my @piq = $summary_rs->search(
                {
                    ep_pick_plate_name => { '!=', undef },
                    crispr_ep_well_id => $crispr_ep_well->crispr_ep_well_id,

                    piq_plate_name => { '!=', undef },
                    piq_well_accepted=> 't',
                    to_report => 't' },
                {
                    select => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    as => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    distinct => 1
                }
            );

            push @piq, $summary_rs->search(
                {
                    ep_pick_plate_name => { '!=', undef },
                    crispr_ep_well_id => $crispr_ep_well->crispr_ep_well_id,

                    ancestor_piq_plate_name => { '!=', undef },
                    ancestor_piq_well_accepted=> 't',
                    to_report => 't' },
                {
                    select => [ qw/ancestor_piq_well_id ancestor_piq_plate_name ancestor_piq_well_name ancestor_piq_well_accepted/ ],
                    as => [ qw/piq_well_id piq_plate_name piq_well_name piq_well_accepted/ ],
                    distinct => 1
                }
            );

            my $piq_pass_count = scalar @piq;

            my @row = (
                "$gene_id",
                "$gene_symbol",
                "$chromosome",
                "$ep_well",
                "$ep_well_ts",
                "$to_report",
                "$cell_line",
                "$design_id",
                "$design_well",
                "$design_type",
                "$dna_template",
                "$assembly",
                "$final_pick",
                "$crispr_id",
                "$crispr_type",
                "$total_colonies",
                "$ep_pick_count",
                "$ep_pick_pass_count",
                "$damage_counts{'frameshift'}",
                "$damage_counts{'in-frame'}",
                "$damage_counts{'wild_type'}",
                "$damage_counts{'mosaic'}",
                "$damage_counts{'no-call'}",
                "$het_count",
                "$piq_pass_count",
            );

            return \@row;

    }

};

__PACKAGE__->meta->make_immutable;

1;

__END__
