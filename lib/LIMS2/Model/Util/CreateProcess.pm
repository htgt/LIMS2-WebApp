package LIMS2::Model::Util::CreateProcess;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            process_fields
            process_plate_types
            process_aux_data_field_list
            check_input_wells
            check_output_wells
          )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::MoreUtils qw( uniq );
use LIMS2::Exception::Implementation;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_INPUT_WELL_CHECK );

my %process_field_data = (
    final_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'final-cassette' ) },
        label  => 'Cassette (Final)',
        name   => 'cassette',
    },
    final_backbone => {
        values => sub{ return _eng_seq_type_list( shift, 'final-backbone' ) },
        label  => 'Backbone (Final)',
        name   => 'backbone',
    },
    intermediate_cassette => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-cassette' ) },
        label  => 'Cassette (Intermediate)',
        name   => 'cassette',
    },
    intermediate_backbone => {
        values => sub{ return _eng_seq_type_list( shift, 'intermediate-backbone' ) },
        label  => 'Backbone (Intermediate)',
        name   => 'backbone',
    },
    cell_line => {
        values => sub{ return },
        label  => 'Cell Line',
        name   => 'cell_line',
    },
    recombinase => {
        values => sub{ return [ map{ $_->id } shift->schema->resultset('Recombinase')->all ] },
        label  => 'Recombinase',
        name   => 'recombinase',
    },
);

sub process_fields {
    my ( $model, $process_type ) = @_;
    my %process_fields;
    my $fields = exists $PROCESS_SPECIFIC_FIELDS{$process_type} ? $PROCESS_SPECIFIC_FIELDS{$process_type} : [];

    for my $field ( @{ $fields } ) {
        LIMS2::Exception::Implementation->throw(
            "Don't know how to setup process field $field"
        ) unless exists $process_field_data{$field};

        my $field_values = $process_field_data{$field}{values}->($model);
        $process_fields{$field} = {
            values => $field_values,
            label  => $process_field_data{$field}{label},
            name   => $process_field_data{$field}{name},
        };
    }

    return \%process_fields;
}

sub _eng_seq_type_list {
    my ( $model, $type ) = @_;

    my $eng_seqs = $model->eng_seq_builder->list_seqs( type => $type );

    return [ map{ $_->{name} } @{ $eng_seqs } ];
}

sub process_plate_types {
    my ( $model, $process_type ) = @_;
    my $plate_types;

    if ( exists $PROCESS_PLATE_TYPES{$process_type} ) {
        $plate_types = $PROCESS_PLATE_TYPES{$process_type};
    }
    else {
        $plate_types = [ map{ $_->id } @{ $model->list_plate_types } ];
    }

    return $plate_types;
}

sub process_aux_data_field_list {
    return [ uniq map{ $process_field_data{$_}{name} } keys %process_field_data ];
}

sub check_input_wells {
    my ( $self, $process ) = @_;

    my $process_type = $process->type_id;

    my @input_wells               = $process->input_wells;
    my $count                     = scalar @input_wells;
    my $expected_input_well_count = $PROCESS_INPUT_WELL_CHECK{$process_type}{number};
    $self->throw( Validation =>
            "$process_type process should have $expected_input_well_count input well(s) (got $count)"
    ) unless $count == $expected_input_well_count;

    return unless exists $PROCESS_INPUT_WELL_CHECK{$process_type}{type};

    my @types = uniq map { $_->plate->type_id } @input_wells;
    my %expected_input_process_types
        = map { $_ => 1 } @{ $PROCESS_INPUT_WELL_CHECK{$process_type}{type} };

    $self->throw( Validation => "$process_type process input well should be type "
            . join( ',', keys %expected_input_process_types )
            . ' (got '
            . join( ',', @types )
            . ')' )
        if notall { exists $expected_input_process_types{$_} } @types;

    return;
}

sub check_output_wells {
    my ( $self, $process ) = @_;

    my $process_type = $process->type_id;

    my @output_wells = $process->output_wells;
    my $count        = scalar @output_wells;
    # Only expect one output well per process, but schema can handle multiple
    $self->throw( Validation => "Process should have 1 output well (got $count)")
        unless $count == 1;

    return unless exists $PROCESS_PLATE_TYPES{$process_type};

    my @types = uniq map { $_->plate->type_id } @output_wells;
    my %expected_output_process_types
        = map { $_ => 1 } @{ $PROCESS_PLATE_TYPES{$process_type} };

    $self->throw( Validation => "$process_type process output well should be type "
            . join( ',', keys %expected_output_process_types )
            . ' (got '
            . join( ',', @types )
            . ')' )
        if notall { exists $expected_output_process_types{$_} } @types;

    return;
}
1;

__END__
