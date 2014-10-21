package LIMS2::t::WebApp::Controller::User::EngSeqs;
use base qw(Test::Class);

use strict;
use Test::Most;
use LIMS2::Test;

use Bio::SeqIO;
use IO::Scalar;

=head1 NAME

LIMS2/t/WebApp/Controller/User/EngSeqs.pm - test class for LIMS2::WebApp::Controller::User::EngSeqs

=cut

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

sub generate_sequence_file : Tests(17) {
    my $mech = mech();

    {
        note("No design id set");
        $mech->get_ok('/user/generate_sequence_file');
        ok my $res = $mech->submit_form(
            form_id => 'generate_sequence',
            fields  => {
                design_id => '',
                cassette  => 'L1L2_GT2_LacZ_BSD',
            },
            button => 'generate_sequence'
            ),
            'submit form';

        ok $res->is_success, '.. response is_success';
        like $res->content, qr/You must specify a design id/, '... correct error message';
    }

    {
        note("No cassette set");
        $mech->get_ok('/user/generate_sequence_file');
        ok my $res = $mech->submit_form(
            form_id => 'generate_sequence',
            fields  => {
                design_id => 84231,
                cassette  => '',
            },
            button => 'generate_sequence'
            ),
            'submit form';

        ok $res->is_success, '.. response is_success';
        like $res->content, qr/You must specify a cassette/, '... correct error message';
    }

    {
        note("Create custom genbank file");
        $mech->get_ok('/user/generate_sequence_file');
        ok my $res = $mech->submit_form(
            form_id => 'generate_sequence',
            fields  => {
                design_id => 84231,
                cassette  => 'L1L2_GT2_LacZ_BSD',
                backbone  => 'R3R4_pBR_amp',
            },
            button => 'generate_sequence'
            ),
            'submit form';

        ok $res->is_success, '.. response is_success';
        my $gbk_content = $res->content;
        my $temp_fh = new IO::Scalar \$gbk_content;
        my $seq_io = Bio::SeqIO->new( -fh => $temp_fh, -format => 'genbank' );
        ok my $bio_seq = $seq_io->next_seq, 'can parse output as genbank file';
        ok $bio_seq->is_circular, '... have vector seq';
        is $bio_seq->species->genus, 'Mus', '... correct species';
        my @comments = map { $_->as_text } $bio_seq->get_Annotations('comment');

        ok grep(/design_id: 84231/, @comments ), '... have correct design_id in comment';
        ok grep(/cassette: L1L2_GT2_LacZ_BSD/, @comments), '... have correct cassette in comment';
        ok grep(/backbone: R3R4_pBR_amp/, @comments), '... have correct backbone in comment';
    }

}

1;

__END__
