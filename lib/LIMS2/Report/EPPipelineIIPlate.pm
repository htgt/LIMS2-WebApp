package LIMS2::Report::EPPipelineIIPlate;

use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
#with qw( LIMS2::ReportGenerator::ColonyCounts );

#has bypass_oligo_assembly => (
#    is         => 'ro',
#    required => 0,
#);

#has orginal_design => (
#    is        =>  'ro',
#    require   => 0,
#);

has wells_data => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_wells_data {
    my ($self) = @_;

    my @wells_data;
    my @well_ids;
    my @rs = $self->model->schema->resultset( 'Well' )->search({ plate_id => $self->plate->id }, { order_by => 'id' })->all;
    foreach my $well (@rs) {
        my $design_id = $self->get_well_design($well->id);
        push @well_ids, $well->id;
        my $temp = {
            well_id => $well->id,
            well_name => $well->name,
            design_id => $design_id
        };
        push @wells_data, $temp;
    }

    return \@wells_data;
}

override plate_types => sub {
    return [ 'EP_PIPELINE_II' ];
};

override _build_name => sub {
    my $self = shift;

    return 'EP Pipeline II Plate ' . $self->plate_name;
};

#override _build_name => sub {
#    my $self = shift;
#};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well ID', 'Well Name', 'Design ID', 'Design Type', 'Plate Name', 'Gene ID', 'Gene Symbol', 'Cell Line', 'Project Name', 'Crispr ID', 'Crispr Location', 'User'
    ];
};

override iterator => sub {
    my $self = shift;

    my @wells_data = @{ $self->wells_data };

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my @data = (
            $well_data->{well_id},
            $well_data->{well_name},
            $well_data->{design_id}
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};

sub get_well_design {
    my ($self, $well_id) = @_;

    my @rec = $self->model->schema->resultset( 'ProcessOutputWell' )->search({ well_id => $well_id  })->all;
    my @process_ids = map { $_->process_id } @rec;

    my @res = $self->model->schema->resultset( 'ProcessDesign' )->search({ process_id =>  $process_ids[0]  })->all;
    my @design_ids = map { $_->design_id } @res;

    return $design_ids[0];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

