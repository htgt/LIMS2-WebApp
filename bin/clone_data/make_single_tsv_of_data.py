from csv import DictWriter

RELEVANT_FIELDS = [
    ("Clone_ID", lambda d: d["clone_id"]),
    ("Plate_Name", lambda d: d["plate_name"]),
    ("Well_Name", lambda d: d["well_name"]),
    ("Gene_Symbol", lambda d: d["gene"]),
    ("Gene_ID", lambda d: d["gene_id"]),
    ("Species", lambda d: d["species"]),
    ("Cell Line", lambda d: d["cell_line"]),
    ("Design_ID", lambda d: d["design_id"]),
    ("Design_Type", lambda d: d["design_type"]),
    ("Primer_EXF_Chromosome", lambda d: _get_oligo_of_type(d, "EXF")["locus"]["chr_name"]),
    ("Primer_EXF_Start", lambda d: _get_oligo_of_type(d, "EXF")["locus"]["chr_start"]),
    ("Primer_EXF_End", lambda d: _get_oligo_of_type(d, "EXF")["locus"]["chr_end"]),
    ("Primer_EXF_Sequence_In_5_3_Orientation", lambda d: _get_oligo_of_type(d, "EXF")["sequence_in_5_to_3_prime_orientation"]),
    ("Primer_INF_Chromosome", lambda d: _get_oligo_of_type(d, "INF")["locus"]["chr_name"]),
    ("Primer_INF_Start", lambda d: _get_oligo_of_type(d, "INF")["locus"]["chr_start"]),
    ("Primer_INF_End", lambda d: _get_oligo_of_type(d, "INF")["locus"]["chr_end"]),
    ("Primer_INF_Sequence_In_5_3_Orientation", lambda d: _get_oligo_of_type(d, "INF")["sequence_in_5_to_3_prime_orientation"]),
    ("Primer_INR_Chromosome", lambda d: _get_oligo_of_type(d, "INR")["locus"]["chr_name"]),
    ("Primer_INR_Start", lambda d: _get_oligo_of_type(d, "INR")["locus"]["chr_start"]),
    ("Primer_INR_End", lambda d: _get_oligo_of_type(d, "INR")["locus"]["chr_end"]),
    ("Primer_INR_Sequence_In_5_3_Orientation", lambda d: _get_oligo_of_type(d, "INR")["sequence_in_5_to_3_prime_orientation"]),
    ("Primer_EXR_Chromosome", lambda d: _get_oligo_of_type(d, "EXR")["locus"]["chr_name"]),
    ("Primer_EXR_Start", lambda d: _get_oligo_of_type(d, "EXR")["locus"]["chr_start"]),
    ("Primer_EXR_End", lambda d: _get_oligo_of_type(d, "EXR")["locus"]["chr_end"]),
    ("Primer_EXR_Sequence_In_5_3_Orientation", lambda d: _get_oligo_of_type(d, "EXR")["sequence_in_5_to_3_prime_orientation"]),
    ("CRISPR_LIMS2_ID", lambda d: d["crispr"]["id"]),
    ("CRISPR_WGE_ID", lambda d: d["crispr"]["wge_crispr_id"]),
    ("CRISPR_Location", lambda d: _make_crispr_location(d)),
    ("CRISPR_Sequence_In_5_3_Orientation", lambda d: d["crispr"]["fwd_seq"]),
    ("CRISPR_Strand", lambda d: d["crispr"]["locus"]["chr_strand"]),
    ("CRISPR_Location_Type", lambda d: d["crispr"]["type"]),
    ("MiSeq_QA_Experiment", lambda d: d["miseq"].get("data", {}).get("experiment_name", "")),
    ("MiSeq_QA_Classification",  lambda d: d["miseq"].get("data", {}).get("classification", "")),
    ("MiSeq_QA_Error",  lambda d: d["miseq"].get("error", "")),
]

def _get_oligo_of_type(data, oligo_type):
    oligos = data["oligos"]
    for oligo in oligos:
        if oligo["type"] == oligo_type:
            return oligo
    raise ValueError(f"No oligo data for type: {oligo_type}")

def _make_crispr_location(data):
    locus_data = data["crispr"]["locus"]
    return f"{locus_data['chr_name']}:{locus_data['chr_start']}-{locus_data['chr_end']}"

def flatten_single_record(clone_data_point):
    return {
        key: data(clone_data_point) for (key, data) in RELEVANT_FIELDS
    }

def create_tsv(data, file_location):
    with open(file_location, "w", newline="") as f:
        writer = DictWriter(f, data[0].keys(), delimiter='\t')
        writer.writeheader()
        for datum in data:
            writer.writerow(datum)

