from unittest import TestCase

from make_single_tsv_of_data import flatten_single_record

TEST_EXAMPLE_JSON = {
  "well_id": 802328,
  "hdr_template": None,
  "species": "Human",
  "experiments": [],
  "plate_name": "HUPFP0085A5",
  "crispr": {
    "fwd_seq": "TTCTTGGGACGAATTCTCTGTGG",
    "off_target_summaries": [
      {
        "outlier": 0,
        "summary": "{0: 1, 1: 0, 2: 0, 3: 13, 4: 119}",
        "algorithm": "exhaustive"
      }
    ],
    "nonsense_crispr_original_crispr_id": None,
    "seq": "CCACAGAGAATTCGTCCCAAGAA",
    "type": "Exonic",
    "locus": {
      "chr_end": 15933482,
      "chr_strand": "-",
      "chr_start": 15933460,
      "assembly": "GRCh38",
      "chr_name": "1"
    },
    "id": 228808,
    "crispr_primers": [],
    "off_targets": [],
    "species": "Human",
    "experiments": {
      "2514": "SPEN_2A1"
    },
    "pam_right": "false",
    "comment": None,
    "wge_crispr_id": 902359285
  },
  "clone_id": "HUPFP0085A5_B10",
  "design_id": 1016966,
  "gene_id": "HGNC:17575",
  "design_type": "miseq-nhej",
  "gene": "SPEN",
  "miseq": {
    "data": {
      "experiment_name": "HUEDQ0593B_SPEN",
      "miseq_well": "M19",
      "miseq_plate": "Miseq_118",
      "allele_data": [
        {
          "n_reads": 1745,
          "unmodified": 0,
          "n_mutated": 0,
          "n_deleted": 0,
          "n_inserted": 1,
          "hdr": 0,
          "nhej": 1,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "percentage_reads": 22.41
        },
        {
          "percentage_reads": 0.96,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCTATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 1,
          "hdr": 0,
          "n_inserted": 1,
          "n_reads": 75,
          "n_deleted": 0,
          "n_mutated": 0,
          "unmodified": 0
        },
        {
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 0,
          "percentage_reads": 23.08,
          "n_deleted": 0,
          "n_mutated": 0,
          "unmodified": 1,
          "n_reads": 1797,
          "hdr": 0,
          "n_inserted": 0
        },
        {
          "n_inserted": 1,
          "hdr": 0,
          "n_reads": 181,
          "unmodified": 0,
          "n_mutated": 0,
          "n_deleted": 0,
          "percentage_reads": 2.32,
          "nhej": 1,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTGCAGGGTGCATTCCATCATT"
        },
        {
          "n_reads": 172,
          "n_deleted": 0,
          "n_mutated": 0,
          "unmodified": 1,
          "hdr": 0,
          "n_inserted": 0,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTGCAGGGTGCATTCCATCATT",
          "nhej": 0,
          "percentage_reads": 2.21
        },
        {
          "hdr": 0,
          "n_inserted": 0,
          "n_reads": 92,
          "n_mutated": 0,
          "n_deleted": 0,
          "unmodified": 1,
          "percentage_reads": 1.18,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACATGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 0
        },
        {
          "percentage_reads": 1.13,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCTATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 0,
          "hdr": 0,
          "n_inserted": 0,
          "unmodified": 1,
          "n_mutated": 0,
          "n_deleted": 0,
          "n_reads": 88
        },
        {
          "nhej": 1,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACATGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCCTCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "percentage_reads": 1.09,
          "n_reads": 85,
          "n_mutated": 0,
          "unmodified": 0,
          "n_deleted": 0,
          "n_inserted": 1,
          "hdr": 0
        },
        {
          "percentage_reads": 0.76,
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCATCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 1,
          "hdr": 0,
          "n_inserted": 1,
          "n_reads": 59,
          "n_mutated": 0,
          "n_deleted": 0,
          "unmodified": 0
        },
        {
          "aligned_sequence": "GGACAACAGTACAGCACCCCGAAGCCCCACAGGAAGAAAAGCAGAGTGAGAAACCCCATTCCACTCCTCCTCAGTCATGTACTTCTGACCTAAGCAAGATTCCCTCCACAGAGAATTCGTCCCAAGAAATCAGTGTTGAGGAAAGGACTCCAACCAAAGCATCTGTGCCCCCAGACCTTCCCCCACCTCCCCAGCCAGCACCGGTGGATGAGGAGCATCAAGCCAGGTTCAGGGTGCATTCCATCATT",
          "nhej": 0,
          "percentage_reads": 0.73,
          "n_reads": 57,
          "unmodified": 1,
          "n_mutated": 0,
          "n_deleted": 0,
          "hdr": 0,
          "n_inserted": 0
        }
      ],
      "indel_data": [
        {
          "indel": 47,
          "frequency": 2
        },
        {
          "indel": 2,
          "frequency": 1
        },
        {
          "indel": 48,
          "frequency": 4
        },
        {
          "frequency": 3904,
          "indel": 1
        },
        {
          "indel": -16,
          "frequency": 4
        },
        {
          "indel": -1,
          "frequency": 4
        },
        {
          "indel": 0,
          "frequency": 3866
        }
      ],
      "classification": "Not Called",
      "total_reads": 7785
    }
  },
  "oligos": [
    {
      "seq": "GCAGTGAAACCTCACACTCA",
      "type": "EXF",
      "sequence_in_5_to_3_prime_orientation": "GCAGTGAAACCTCACACTCA",
      "id": 202421,
      "locus": {
        "chr_start": 15933154,
        "chr_end": 15933173,
        "chr_strand": 1,
        "chr_name": "1",
        "assembly": "GRCh38",
        "species": "Human"
      }
    },
    {
      "id": 202422,
      "locus": {
        "chr_start": 15933355,
        "chr_end": 15933373,
        "chr_strand": 1,
        "species": "Human",
        "chr_name": "1",
        "assembly": "GRCh38"
      },
      "sequence_in_5_to_3_prime_orientation": "GGACAACAGTACAGCACCC",
      "type": "INF",
      "seq": "GGACAACAGTACAGCACCC"
    },
    {
      "id": 202423,
      "locus": {
        "chr_start": 15933582,
        "chr_end": 15933602,
        "chr_strand": 1,
        "assembly": "GRCh38",
        "chr_name": "1",
        "species": "Human"
      },
      "type": "INR",
      "seq": "TTCAGGGTGCATTCCATCATT",
      "sequence_in_5_to_3_prime_orientation": "AATGATGGAATGCACCCTGAA"
    },
    {
      "locus": {
        "chr_start": 15933723,
        "chr_end": 15933743,
        "chr_strand": 1,
        "assembly": "GRCh38",
        "chr_name": "1",
        "species": "Human"
      },
      "id": 202420,
      "seq": "CCTACTAAGGTGACAGAGTGG",
      "type": "EXR",
      "sequence_in_5_to_3_prime_orientation": "CCACTCTGTCACCTTAGTAGG"
    }
  ],
  "well_name": "B10",
  "barcode": None,
  "cell_line": "KOLF_2_C1-ARID2(wt/wt)"
}

TEST_EXAMPLE_WITH_NO_MISEQ_DATA = {
  "plate_name": "HUPFP0019_3",
  "crispr": {
    "wge_crispr_id": 1002146989,
    "comment": None,
    "pam_right": "true",
    "off_targets": [],
    "crispr_primers": [],
    "experiments": {
      "2168": "NSD1_1",
      "2169": "NSD1_1_2"
    },
    "species": "Human",
    "id": 228043,
    "locus": {
      "assembly": "GRCh38",
      "chr_name": "5",
      "chr_strand": "+",
      "chr_end": 177191967,
      "chr_start": 177191945
    },
    "nonsense_crispr_original_crispr_id": None,
    "off_target_summaries": [
      {
        "algorithm": "exhaustive",
        "summary": "{0: 1, 1: 0, 2: 0, 3: 4, 4: 58}",
        "outlier": 0
      }
    ],
    "seq": "AATTCAAGAGACGCCCATGGTGG",
    "fwd_seq": "AATTCAAGAGACGCCCATGGTGG",
    "type": "Exonic"
  },
  "species": "Human",
  "experiments": [],
  "hdr_template": None,
  "well_id": 706969,
  "gene_id": "HGNC:14234",
  "design_type": "miseq-nhej",
  "design_id": 1016516,
  "clone_id": "HUPFP0019_3_A03",
  "miseq": {
    "error": "Not on HUEDQ0517 and can't find anywhere else"
  },
  "gene": "NSD1",
  "barcode": None,
  "cell_line": "KOLF_2_C1",
  "well_name": "A03",
  "oligos": [
    {
      "sequence_in_5_to_3_prime_orientation": "AGTTGAGAACTATGTATAAAGGGC",
      "seq": "AGTTGAGAACTATGTATAAAGGGC",
      "type": "EXF",
      "id": 200633,
      "locus": {
        "chr_strand": 1,
        "chr_end": 177191702,
        "chr_start": 177191679,
        "assembly": "GRCh38",
        "chr_name": "5",
        "species": "Human"
      }
    },
    {
      "locus": {
        "chr_start": 177191857,
        "chr_end": 177191876,
        "chr_strand": 1,
        "species": "Human",
        "chr_name": "5",
        "assembly": "GRCh38"
      },
      "id": 200634,
      "sequence_in_5_to_3_prime_orientation": "GATGCCCCATGTTTTGTCTG",
      "seq": "GATGCCCCATGTTTTGTCTG",
      "type": "INF"
    },
    {
      "type": "INR",
      "seq": "AAAATGAAAGGTAATACTTGCAGTG",
      "sequence_in_5_to_3_prime_orientation": "CACTGCAAGTATTACCTTTCATTTT",
      "id": 200635,
      "locus": {
        "species": "Human",
        "chr_name": "5",
        "assembly": "GRCh38",
        "chr_start": 177192010,
        "chr_strand": 1,
        "chr_end": 177192034
      }
    },
    {
      "id": 200632,
      "locus": {
        "chr_end": 177192200,
        "chr_strand": 1,
        "chr_start": 177192176,
        "chr_name": "5",
        "assembly": "GRCh38",
        "species": "Human"
      },
      "sequence_in_5_to_3_prime_orientation": "TGAGAGAAGGTTTAAATCATAGAGT",
      "seq": "ACTCTATGATTTAAACCTTCTCTCA",
      "type": "EXR"
    }
  ]
}


class TestFlatteningOfRecord(TestCase):

    maxDiff = None

    def test_it_works(self):
        expected_data = {
            "Clone_ID": "HUPFP0085A5_B10",
            "Plate_Name": "HUPFP0085A5",
            "Well_Name": "B10",
            "Gene_Symbol": "SPEN",
            "Gene_ID": "HGNC:17575",
            "Species": "Human",
            "Cell Line": "KOLF_2_C1-ARID2(wt/wt)",
            "Design_ID": 1016966,
            "Design_Type": "miseq-nhej",
            "Primer_EXF_Chromosome": "1",
            "Primer_EXF_Start": 15933154,
            "Primer_EXF_End": 15933173,
            "Primer_EXF_Sequence_In_5_3_Orientation": "GCAGTGAAACCTCACACTCA",
            "Primer_INF_Chromosome": "1",
            "Primer_INF_Start": 15933355,
            "Primer_INF_End": 15933373,
            "Primer_INF_Sequence_In_5_3_Orientation": "GGACAACAGTACAGCACCC",
            "Primer_INR_Chromosome": "1",
            "Primer_INR_Start": 15933582,
            "Primer_INR_End": 15933602,
            "Primer_INR_Sequence_In_5_3_Orientation": "AATGATGGAATGCACCCTGAA",
            "Primer_EXR_Chromosome": "1",
            "Primer_EXR_Start": 15933723,
            "Primer_EXR_End": 15933743,
            "Primer_EXR_Sequence_In_5_3_Orientation": "CCACTCTGTCACCTTAGTAGG",
            "CRISPR_LIMS2_ID": 228808,
            "CRISPR_WGE_ID": 902359285,
            "CRISPR_Location": "1:15933460-15933482",
            "CRISPR_Sequence_In_5_3_Orientation": "TTCTTGGGACGAATTCTCTGTGG",
            "CRISPR_Strand": "-",
            "CRISPR_Location_Type": "Exonic",
            "MiSeq_QA_Experiment": "HUEDQ0593B_SPEN",
            "MiSeq_QA_Classification": "Not Called",
            "MiSeq_QA_Error": "",
        }

        flattened = flatten_single_record(TEST_EXAMPLE_JSON)

        self.assertEqual(flattened, expected_data)

    def test_missing_miseq_case(self):

        flattened = flatten_single_record(TEST_EXAMPLE_WITH_NO_MISEQ_DATA)

        self.assertEqual(flattened["MiSeq_QA_Experiment"], "")
        self.assertEqual(flattened["MiSeq_QA_Classification"], "")
        self.assertEqual(flattened["MiSeq_QA_Error"], "Not on HUEDQ0517 and can't find anywhere else")
