package LIMS2::t::WebApp::Controller::User::BatchDesign;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::BatchDesign;
#alias the class to be tested so don't need to keep fully referencing it
BEGIN { *BatchDesign:: = \*LIMS2::WebApp::Controller::User::BatchDesign:: };
use strict;

sub validate_columns : Test(3) {
    note('all columns included');
    {
        my @columns = ('WGE_ID', 'Design_Type', 'CRISPR_ID', 'CRISPR Sequence', 'PCR forward',
            'PCR reverse', 'MiSEQ forward', 'MiSEQ reverse', 'HDR template');
        ok not BatchDesign::_validate_columns(\@columns);
    }
    note('Some columns missing');
    {
        my @columns = ('WGE_ID', 'CRISPR Sequence', 'PCR forward',
            'PCR reverse', 'MiSEQ reverse');
        ok my $error = BatchDesign::_validate_columns(\@columns);
        is($error, 'Missing required columns: Design_Type, CRISPR_ID, MiSEQ forward');
    }
}

sub validate_values : Test(11) {
    my $data = {
        i => 12345,
        j => -13,
        k => 42,
        CRISPR_ID => 'ATG16L1_1v2',
        symbol => 'PTENP1-202',
        seq => 'ACTGCTGA',
        missing_seq => 'NGG',
        type => 'fusion',
    };
    note('all checked values ok');
    ok not BatchDesign::_validate_values( $data, 'NUMERIC', [qw/i k/] );
    ok not BatchDesign::_validate_values( $data, 'GENE', [qw/CRISPR_ID symbol/] );
    ok not BatchDesign::_validate_values( $data, 'SEQUENCE', [qw/seq/] );

    note('some checked values bad');
    {
        ok my $error = BatchDesign::_validate_values( $data, 'NUMERIC', [qw/i j k/] ); 
        is($error, q/'-13' is not a valid value for j/);
        ok $error = BatchDesign::_validate_values( $data, 'TYPE', [qw/type/] ); 
        is($error, q/'fusion' is not a valid value for type/);
        ok $error = BatchDesign::_validate_values( $data, 'GENE', [qw/j symbol/] ); 
        is($error, q/'-13' is not a valid value for j/);
        ok $error = BatchDesign::_validate_values( $data, 'SEQUENCE', 
            [qw/seq missing_seq/] ); 
        is($error, q/'NGG' is not a valid value for missing_seq/);
    }
}

sub validate_sequences : Test(3) {
    my $primers = {
        exf => { seq => 'ACTGACTG' },
        inf => { seq => 'ACTGACTG' },
        exr => { seq => 'ACTGACTG' },
    };
    ok not BatchDesign::_validate_sequences( $primers );
    $primers->{inr}->{seq} = 'CAGTNCAGT';
    ok my $error = BatchDesign::_validate_sequences ( $primers );
    is($error, q/'CAGTNCAGT' is not a valid inr primer/);
}

sub _make_loci {
    my ( $chr, $strand, $start ) = @_;
    return {
            chr_name => $chr,
            chr_strand => $strand,
            chr_start => $start,
            chr_end => $start + 100
    };
}

sub _make_valid_primers {
    my $strand = shift // 1;
    my @oligos = ($strand > 0) ? qw/exf exr inf inr/ : qw/exr exf inr inf/;
    return {
        $oligos[0] => { loci => _make_loci( 1, $strand, 40000 ), seq => 'TACGG' },
        $oligos[1] => { loci => _make_loci( 1, $strand, 42900 ), seq => 'CCTAG' },
        $oligos[2] => { loci => _make_loci( 1, $strand, 41200 ), seq => 'CATGG' },
        $oligos[3] => { loci => _make_loci( 1, $strand, 41700 ), seq => 'CCGAT' },
    };
}

sub _test_genome_distance {
    my ( $strand, $oligo, $position, $expected_error ) = @_;
    my $primers = _make_valid_primers($strand);
    $primers->{$oligo}->{loci}->{chr_start} = $position;
    $primers->{$oligo}->{loci}->{chr_end} = $position + 100;
    ok my $error = BatchDesign::_validate_primers( $primers );
    is($error, $expected_error);
    return;
}

sub validate_primers : Test(21) {
    note('all ok');
    {
        my $primers = _make_valid_primers;
        ok not BatchDesign::_validate_primers( $primers );
    }

    note('chromosome mismatch');
    {
        my $primers = _make_valid_primers;
        $primers->{exr}->{loci}->{chr_name} = 2;
        ok my $error = BatchDesign::_validate_primers( $primers );
        is($error, 'Oligos have inconsistent chromosomes');
    }
    
    note('strand mismatch');
    {
        my $primers = _make_valid_primers;
        $primers->{exr}->{loci}->{chr_strand} = -1;
        ok my $error = BatchDesign::_validate_primers( $primers );
        is($error, 'Oligos have inconsistent strands');
    }

    note('external primers too far apart');
    {
        _test_genome_distance(1, 'exf', 30000, 'External oligos are 12800bp apart');
        _test_genome_distance(1, 'exr', 50000, 'External oligos are 9900bp apart');
        _test_genome_distance(0, 'exr', 31000, 'External oligos are 11800bp apart');
        _test_genome_distance(0, 'exf', 49000, 'External oligos are 8900bp apart');
    }
    
    note('internal primers too far apart');
    {
        _test_genome_distance(1, 'inf', 40200, 'Internal oligos are 1400bp apart');
        _test_genome_distance(1, 'inr', 42600, 'Internal oligos are 1300bp apart');
        _test_genome_distance(0, 'inr', 40300, 'Internal oligos are 1300bp apart');
        _test_genome_distance(0, 'inf', 42500, 'Internal oligos are 1200bp apart');
    }
}

sub create_oligos : Test(10) {
    note('forward strand');
    {
        my $primers = _make_valid_primers; 
        ok my %oligos = map { $_->{type} => $_ }
            @{ BatchDesign::_create_oligos($primers) };
        is($oligos{EXF}->{seq}, 'TACGG');
        is($oligos{EXR}->{seq}, 'CTAGG'); #revcom
        is($oligos{INF}->{seq}, 'CATGG');
        is($oligos{INR}->{seq}, 'ATCGG'); #revcom
    }
    note('reverse strand');
    {
        my $primers = _make_valid_primers(-1); 
        ok my %oligos = map { $_->{type} => $_ }
            @{ BatchDesign::_create_oligos($primers) };
        is($oligos{EXF}->{seq}, 'CTAGG'); #revcom
        is($oligos{EXR}->{seq}, 'TACGG');
        is($oligos{INF}->{seq}, 'ATCGG'); #revcom
        is($oligos{INR}->{seq}, 'CATGG');
    }
}

1;
