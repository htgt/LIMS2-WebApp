package LIMS2::t::WebApp::Controller::User::CreateMiseqDesign;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::CreateMiseqDesign;

use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';

use Test::More skip_all => "See LIMS 2.0 - Issue 12653";

use strict;

BEGIN { *CreateMiseqDesign:: = \*LIMS2::Model::Util::CreateMiseqDesign:: };

my $mech = LIMS2::Test::mech();

sub all_tests  : Test(21)
{
    my $self = shift;
    my $details = {
        name => 'test_user@example.org',
        species => 'Human',
    };

    {       
	note ( "Default preset checks" );
    ok my $params = CreateMiseqDesign::design_preset_params($self, 'Default');
    is ($params->{genomic_threshold}, 30, "Default Genomic Threshold check");
    $params->{design_type} = 'miseq-nhej';

    ok my $pass_design = CreateMiseqDesign::generate_miseq_design($self, $params, 187845, $details), 'Successful default design';
    is ($pass_design->{crispr}, 187845, 'New design is based on original crispr');
    isnt ($pass_design->{design}->id, "", 'New design has ID');
    ok my $geno_threshold_fail = CreateMiseqDesign::generate_miseq_design($self, $params, 188511, $details), 'Geno threshold default preset fail';
    like ($geno_threshold_fail->{error},qr/PCR genomic uniqueness check failed/, 'Geno threshold fail error check');
    ok my $primer_gen_fail = CreateMiseqDesign::generate_miseq_design($self, $params, 189889, $details), 'Primer generation default preset fail';
    like ($primer_gen_fail->{error}, qr/Primer generation failed/, 'Primer gen fail error check');
    }

    {
    note( "New preset checks" );
    my $new_preset_params = {
        name    => 'Pineapple',
        created_by  => 1000,
        genomic_threshold   => 15,
        gc  => {
            min => 45,
            opt => 50,
            max => 55,
        },
        mt  => {
            min => 57,
            opt => 60,
            max => 63,
        },
        primers => {
            miseq   => {
                widths  => {
                    increment   => 15,
                    offset  => 60,
                    search  => 155,
                },
            },
            pcr     => {
                widths  => {
                    increment   => 35,
                    offset  => 155,
                    search  => 375,
                },
            },
        },
    };

    ok my $new_preset = model('Golgi')->create_primer_preset($new_preset_params), 'Created new preset';
    is ($new_preset->name, 'Pineapple', 'Check new preset name');
    ok my $new_params = CreateMiseqDesign::design_preset_params($self, 'Pineapple'), 'Format new preset';
    is ($new_params->{genomic_threshold}, 15, "New preset retrieval check");
    $new_params->{design_type} = 'miseq-nhej';

    ok my $new_pass_design = CreateMiseqDesign::generate_miseq_design($self, $new_params, 187845, $details), 'Successful new preset design';
    is ($new_pass_design->{crispr}, 187845, 'New design is based on original crispr');
    isnt ($new_pass_design->{design}->id, "", 'New design has ID');
    ok my $new_geno_threshold_pass = CreateMiseqDesign::generate_miseq_design($self, $new_params, 188511, $details), 'Geno threshold new preset pass';
    is ($new_geno_threshold_pass->{crispr_id}, 188511, 'New design is based on original crispr');
    isnt ($new_geno_threshold_pass->{design_id}, "", 'New design has ID');
    ok my $new_primer_gen_fail = CreateMiseqDesign::generate_miseq_design($self, $new_params, 189889, $details), 'Primer generation default preset fail';
    like ($new_primer_gen_fail->{error}, qr/Primer generation failed/, 'Primer gen fail error check');
    }

}

1;

__END__
