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

my %process_field_values = (
    final_cassette        => sub{ return _eng_seq_type_list( shift, 'final-cassette' ) },
    final_backbone        => sub{ return _eng_seq_type_list( shift, 'final-backbone' ) },
    intermediate_cassette => sub{ return _eng_seq_type_list( shift, 'intermediate-cassette' ) },
    intermediate_backbone => sub{ return _eng_seq_type_list( shift, 'intermediate-backbone' ) },
    cell_line             => sub{ return },
    recombinase           => sub{ return [ map{ $_->id } shift->schema->resultset('Recombinase')->all ] },
);

sub process_fields {
    my ( $model, $process_type ) = @_;
    my %process_fields;
    my $fields = exists $PROCESS_SPECIFIC_FIELDS{$process_type} ? $PROCESS_SPECIFIC_FIELDS{$process_type} : [];

    for my $field ( @{ $fields } ) {
        LIMS2::Exception::Implementation->throw(
            "Don't know how to setup process field $field"
        ) unless exists $process_field_values{$field};

        $process_fields{$field} = $process_field_values{$field}->($model);
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
    return [ uniq map{ @{ $_ } } values %PROCESS_SPECIFIC_FIELDS ];
}
1;

__END__
