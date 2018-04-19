package LIMS2::Model::Util::WellName;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::WellName::VERSION = '0.495';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( to96 to384 generate_96_well_annotations ) ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;

const our %ninetySix_to_384 => (
    'A01_1' => 'A01',
    'A01_2' => 'A02',
    'A01_3' => 'B01',
    'A01_4' => 'B02',
    'B01_1' => 'C01',
    'B01_2' => 'C02',
    'B01_3' => 'D01',
    'B01_4' => 'D02',
    'C01_1' => 'E01',
    'C01_2' => 'E02',
    'C01_3' => 'F01',
    'C01_4' => 'F02',
    'D01_1' => 'G01',
    'D01_2' => 'G02',
    'D01_3' => 'H01',
    'D01_4' => 'H02',
    'E01_1' => 'I01',
    'E01_2' => 'I02',
    'E01_3' => 'J01',
    'E01_4' => 'J02',
    'F01_1' => 'K01',
    'F01_2' => 'K02',
    'F01_3' => 'L01',
    'F01_4' => 'L02',
    'G01_1' => 'M01',
    'G01_2' => 'M02',
    'G01_3' => 'N01',
    'G01_4' => 'N02',
    'H01_1' => 'O01',
    'H01_2' => 'O02',
    'H01_3' => 'P01',
    'H01_4' => 'P02',
    'A02_1' => 'A03',
    'A02_2' => 'A04',
    'A02_3' => 'B03',
    'A02_4' => 'B04',
    'B02_1' => 'C03',
    'B02_2' => 'C04',
    'B02_3' => 'D03',
    'B02_4' => 'D04',
    'C02_1' => 'E03',
    'C02_2' => 'E04',
    'C02_3' => 'F03',
    'C02_4' => 'F04',
    'D02_1' => 'G03',
    'D02_2' => 'G04',
    'D02_3' => 'H03',
    'D02_4' => 'H04',
    'E02_1' => 'I03',
    'E02_2' => 'I04',
    'E02_3' => 'J03',
    'E02_4' => 'J04',
    'F02_1' => 'K03',
    'F02_2' => 'K04',
    'F02_3' => 'L03',
    'F02_4' => 'L04',
    'G02_1' => 'M03',
    'G02_2' => 'M04',
    'G02_3' => 'N03',
    'G02_4' => 'N04',
    'H02_1' => 'O03',
    'H02_2' => 'O04',
    'H02_3' => 'P03',
    'H02_4' => 'P04',
    'A03_1' => 'A05',
    'A03_2' => 'A06',
    'A03_3' => 'B05',
    'A03_4' => 'B06',
    'B03_1' => 'C05',
    'B03_2' => 'C06',
    'B03_3' => 'D05',
    'B03_4' => 'D06',
    'C03_1' => 'E05',
    'C03_2' => 'E06',
    'C03_3' => 'F05',
    'C03_4' => 'F06',
    'D03_1' => 'G05',
    'D03_2' => 'G06',
    'D03_3' => 'H05',
    'D03_4' => 'H06',
    'E03_1' => 'I05',
    'E03_2' => 'I06',
    'E03_3' => 'J05',
    'E03_4' => 'J06',
    'F03_1' => 'K05',
    'F03_2' => 'K06',
    'F03_3' => 'L05',
    'F03_4' => 'L06',
    'G03_1' => 'M05',
    'G03_2' => 'M06',
    'G03_3' => 'N05',
    'G03_4' => 'N06',
    'H03_1' => 'O05',
    'H03_2' => 'O06',
    'H03_3' => 'P05',
    'H03_4' => 'P06',
    'A04_1' => 'A07',
    'A04_2' => 'A08',
    'A04_3' => 'B07',
    'A04_4' => 'B08',
    'B04_1' => 'C07',
    'B04_2' => 'C08',
    'B04_3' => 'D07',
    'B04_4' => 'D08',
    'C04_1' => 'E07',
    'C04_2' => 'E08',
    'C04_3' => 'F07',
    'C04_4' => 'F08',
    'D04_1' => 'G07',
    'D04_2' => 'G08',
    'D04_3' => 'H07',
    'D04_4' => 'H08',
    'E04_1' => 'I07',
    'E04_2' => 'I08',
    'E04_3' => 'J07',
    'E04_4' => 'J08',
    'F04_1' => 'K07',
    'F04_2' => 'K08',
    'F04_3' => 'L07',
    'F04_4' => 'L08',
    'G04_1' => 'M07',
    'G04_2' => 'M08',
    'G04_3' => 'N07',
    'G04_4' => 'N08',
    'H04_1' => 'O07',
    'H04_2' => 'O08',
    'H04_3' => 'P07',
    'H04_4' => 'P08',
    'A05_1' => 'A09',
    'A05_2' => 'A10',
    'A05_3' => 'B09',
    'A05_4' => 'B10',
    'B05_1' => 'C09',
    'B05_2' => 'C10',
    'B05_3' => 'D09',
    'B05_4' => 'D10',
    'C05_1' => 'E09',
    'C05_2' => 'E10',
    'C05_3' => 'F09',
    'C05_4' => 'F10',
    'D05_1' => 'G09',
    'D05_2' => 'G10',
    'D05_3' => 'H09',
    'D05_4' => 'H10',
    'E05_1' => 'I09',
    'E05_2' => 'I10',
    'E05_3' => 'J09',
    'E05_4' => 'J10',
    'F05_1' => 'K09',
    'F05_2' => 'K10',
    'F05_3' => 'L09',
    'F05_4' => 'L10',
    'G05_1' => 'M09',
    'G05_2' => 'M10',
    'G05_3' => 'N09',
    'G05_4' => 'N10',
    'H05_1' => 'O09',
    'H05_2' => 'O10',
    'H05_3' => 'P09',
    'H05_4' => 'P10',
    'A06_1' => 'A11',
    'A06_2' => 'A12',
    'A06_3' => 'B11',
    'A06_4' => 'B12',
    'B06_1' => 'C11',
    'B06_2' => 'C12',
    'B06_3' => 'D11',
    'B06_4' => 'D12',
    'C06_1' => 'E11',
    'C06_2' => 'E12',
    'C06_3' => 'F11',
    'C06_4' => 'F12',
    'D06_1' => 'G11',
    'D06_2' => 'G12',
    'D06_3' => 'H11',
    'D06_4' => 'H12',
    'E06_1' => 'I11',
    'E06_2' => 'I12',
    'E06_3' => 'J11',
    'E06_4' => 'J12',
    'F06_1' => 'K11',
    'F06_2' => 'K12',
    'F06_3' => 'L11',
    'F06_4' => 'L12',
    'G06_1' => 'M11',
    'G06_2' => 'M12',
    'G06_3' => 'N11',
    'G06_4' => 'N12',
    'H06_1' => 'O11',
    'H06_2' => 'O12',
    'H06_3' => 'P11',
    'H06_4' => 'P12',
    'A07_1' => 'A13',
    'A07_2' => 'A14',
    'A07_3' => 'B13',
    'A07_4' => 'B14',
    'B07_1' => 'C13',
    'B07_2' => 'C14',
    'B07_3' => 'D13',
    'B07_4' => 'D14',
    'C07_1' => 'E13',
    'C07_2' => 'E14',
    'C07_3' => 'F13',
    'C07_4' => 'F14',
    'D07_1' => 'G13',
    'D07_2' => 'G14',
    'D07_3' => 'H13',
    'D07_4' => 'H14',
    'E07_1' => 'I13',
    'E07_2' => 'I14',
    'E07_3' => 'J13',
    'E07_4' => 'J14',
    'F07_1' => 'K13',
    'F07_2' => 'K14',
    'F07_3' => 'L13',
    'F07_4' => 'L14',
    'G07_1' => 'M13',
    'G07_2' => 'M14',
    'G07_3' => 'N13',
    'G07_4' => 'N14',
    'H07_1' => 'O13',
    'H07_2' => 'O14',
    'H07_3' => 'P13',
    'H07_4' => 'P14',
    'A08_1' => 'A15',
    'A08_2' => 'A16',
    'A08_3' => 'B15',
    'A08_4' => 'B16',
    'B08_1' => 'C15',
    'B08_2' => 'C16',
    'B08_3' => 'D15',
    'B08_4' => 'D16',
    'C08_1' => 'E15',
    'C08_2' => 'E16',
    'C08_3' => 'F15',
    'C08_4' => 'F16',
    'D08_1' => 'G15',
    'D08_2' => 'G16',
    'D08_3' => 'H15',
    'D08_4' => 'H16',
    'E08_1' => 'I15',
    'E08_2' => 'I16',
    'E08_3' => 'J15',
    'E08_4' => 'J16',
    'F08_1' => 'K15',
    'F08_2' => 'K16',
    'F08_3' => 'L15',
    'F08_4' => 'L16',
    'G08_1' => 'M15',
    'G08_2' => 'M16',
    'G08_3' => 'N15',
    'G08_4' => 'N16',
    'H08_1' => 'O15',
    'H08_2' => 'O16',
    'H08_3' => 'P15',
    'H08_4' => 'P16',
    'A09_1' => 'A17',
    'A09_2' => 'A18',
    'A09_3' => 'B17',
    'A09_4' => 'B18',
    'B09_1' => 'C17',
    'B09_2' => 'C18',
    'B09_3' => 'D17',
    'B09_4' => 'D18',
    'C09_1' => 'E17',
    'C09_2' => 'E18',
    'C09_3' => 'F17',
    'C09_4' => 'F18',
    'D09_1' => 'G17',
    'D09_2' => 'G18',
    'D09_3' => 'H17',
    'D09_4' => 'H18',
    'E09_1' => 'I17',
    'E09_2' => 'I18',
    'E09_3' => 'J17',
    'E09_4' => 'J18',
    'F09_1' => 'K17',
    'F09_2' => 'K18',
    'F09_3' => 'L17',
    'F09_4' => 'L18',
    'G09_1' => 'M17',
    'G09_2' => 'M18',
    'G09_3' => 'N17',
    'G09_4' => 'N18',
    'H09_1' => 'O17',
    'H09_2' => 'O18',
    'H09_3' => 'P17',
    'H09_4' => 'P18',
    'A10_1' => 'A19',
    'A10_2' => 'A20',
    'A10_3' => 'B19',
    'A10_4' => 'B20',
    'B10_1' => 'C19',
    'B10_2' => 'C20',
    'B10_3' => 'D19',
    'B10_4' => 'D20',
    'C10_1' => 'E19',
    'C10_2' => 'E20',
    'C10_3' => 'F19',
    'C10_4' => 'F20',
    'D10_1' => 'G19',
    'D10_2' => 'G20',
    'D10_3' => 'H19',
    'D10_4' => 'H20',
    'E10_1' => 'I19',
    'E10_2' => 'I20',
    'E10_3' => 'J19',
    'E10_4' => 'J20',
    'F10_1' => 'K19',
    'F10_2' => 'K20',
    'F10_3' => 'L19',
    'F10_4' => 'L20',
    'G10_1' => 'M19',
    'G10_2' => 'M20',
    'G10_3' => 'N19',
    'G10_4' => 'N20',
    'H10_1' => 'O19',
    'H10_2' => 'O20',
    'H10_3' => 'P19',
    'H10_4' => 'P20',
    'A11_1' => 'A21',
    'A11_2' => 'A22',
    'A11_3' => 'B21',
    'A11_4' => 'B22',
    'B11_1' => 'C21',
    'B11_2' => 'C22',
    'B11_3' => 'D21',
    'B11_4' => 'D22',
    'C11_1' => 'E21',
    'C11_2' => 'E22',
    'C11_3' => 'F21',
    'C11_4' => 'F22',
    'D11_1' => 'G21',
    'D11_2' => 'G22',
    'D11_3' => 'H21',
    'D11_4' => 'H22',
    'E11_1' => 'I21',
    'E11_2' => 'I22',
    'E11_3' => 'J21',
    'E11_4' => 'J22',
    'F11_1' => 'K21',
    'F11_2' => 'K22',
    'F11_3' => 'L21',
    'F11_4' => 'L22',
    'G11_1' => 'M21',
    'G11_2' => 'M22',
    'G11_3' => 'N21',
    'G11_4' => 'N22',
    'H11_1' => 'O21',
    'H11_2' => 'O22',
    'H11_3' => 'P21',
    'H11_4' => 'P22',
    'A12_1' => 'A23',
    'A12_2' => 'A24',
    'A12_3' => 'B23',
    'A12_4' => 'B24',
    'B12_1' => 'C23',
    'B12_2' => 'C24',
    'B12_3' => 'D23',
    'B12_4' => 'D24',
    'C12_1' => 'E23',
    'C12_2' => 'E24',
    'C12_3' => 'F23',
    'C12_4' => 'F24',
    'D12_1' => 'G23',
    'D12_2' => 'G24',
    'D12_3' => 'H23',
    'D12_4' => 'H24',
    'E12_1' => 'I23',
    'E12_2' => 'I24',
    'E12_3' => 'J23',
    'E12_4' => 'J24',
    'F12_1' => 'K23',
    'F12_2' => 'K24',
    'F12_3' => 'L23',
    'F12_4' => 'L24',
    'G12_1' => 'M23',
    'G12_2' => 'M24',
    'G12_3' => 'N23',
    'G12_4' => 'N24',
    'H12_1' => 'O23',
    'H12_2' => 'O24',
    'H12_3' => 'P23',
    'H12_4' => 'P24',
);

const our %threeEightFour_to_96 => reverse %ninetySix_to_384;
sub to96 {
    my ( $well_name ) = @_;
    return $threeEightFour_to_96{ uc $well_name };
}

sub to384 {
  my ( $plate_name, $well_name ) = @_;
  my ( $quadrant ) = $plate_name =~ /^.*_(\d+)$/
      or return '';

  while ( $quadrant > 4 ) {
      $quadrant -= 4;
  }
  return $ninetySix_to_384{ uc $well_name . '_' . $quadrant };
}

sub generate_96_well_annotations
{
    my $wells;
    my @letters = qw(A B C D E F G H);
    my $counter = 0;

    for my $letter (@letters)
    {
        for my $numb (1..12)
        {
            $counter++;
            my $edited = sprintf("%02d", $numb);
            my $item = join("", $letter, $edited);
            $wells->{$counter} = $item;
        }
    }
    return $wells;
}

1;
