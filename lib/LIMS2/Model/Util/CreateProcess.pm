package LIMS2::Model::Util::CreateProcess;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            process_fields
            process_plate_types
            process_aux_data_field_list
          )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::MoreUtils qw( uniq );
use LIMS2::Exception;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES );

const my %PROCESS_SPECIFIC_FIELDS => (
    int_recom             => [ qw( intermediate_cassette intermediate_backbone ) ],
    cre_bac_recom         => [ qw( intermediate_cassette intermediate_backbone ) ],
    '2w_gateway'          => [ qw( final_cassette final_backbone recombinase ) ],
    '3w_gateway'          => [ qw( final_cassette final_backbone recombinase ) ],
    recombinase           => [ qw( recombinase ) ],
    first_electroporation => [ qw( cell_line ) ],
);

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
1;

__END__
