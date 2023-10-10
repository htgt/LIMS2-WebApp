from csv import DictWriter
from check_it import check_clone_data
from clone_data_fixer_upper import init
from analyse_it import convert_alphanumeric_well_name_to_numeric as to_numeric
init("lims2:team87@htgt-db.internal.sanger.ac.uk:5440/lims2_clone_data")
from clone_data_fixer_upper import get_clones
clones = get_clones(expected_number_of_clones=1866)
def get_miseq_related_data(data):
    return {
        "fp_plate": data["plate_name"],
        "fp_well": data["well_name"],
        "miseq_plate": data["miseq"]["data"]["miseq_plate"],
        "miseq_well": to_numeric(data["miseq"]["data"]["miseq_well"]),
        "miseq_experiment": data["miseq"]["data"]["experiment_name"]
    }

def get_readcount_data(data):
    return {
        "fp_plate": data["plate_name"],
        "fp_well": data["well_name"],
        "total_reads": data["miseq"]["data"]["total_reads"],
    }

def get_classification_data(data):
    return {
        "fp_plate": data["plate_name"],
        "fp_well": data["well_name"],
        "miseq_plate": data["miseq"]["data"]["miseq_plate"],
        "miseq_well": to_numeric(data["miseq"]["data"]["miseq_well"]),
        "classification": data["miseq"]["data"]["classification"],
    }
    
def filter_results_data_for_good_clones(results):
    return [
        result.json_data for result in results if result.error is None
    ]
    
def transform_to_miseq_data(data):
    return [
        get_miseq_related_data(datum) for datum in data
    ]

def transform_to_read_count_data(data):
    return [
        get_readcount_data(datum) for datum in data
    ]

def transform_to_classification_data(data):
    return [
        get_classification_data(datum) for datum in data
    ]

get_classification_data
    
def order_by_fp(data):
    return sorted(data, key=lambda d: (d["fp_plate"], d["fp_well"]))
    
def order_by_total_reads(data):
    return sorted(data, key=lambda d: d["total_reads"])
    
def get_all_relevant_good_clone_data():
    return order_by_fp(
            transform_to_miseq_data(
                filter_results_data_for_good_clones(
                    check_clone_data(
                        get_clones(expected_number_of_clones=1866)
                    )
                )
            )
        )

def get_read_counts_for_all_good_clones():
    return order_by_total_reads(
            transform_to_read_count_data(
                filter_results_data_for_good_clones(
                    check_clone_data(
                        get_clones(expected_number_of_clones=1866)
                    )
                )
            )
        )

def get_classification_for_all_good_clones():
    return order_by_fp(
            transform_to_classification_data(
                filter_results_data_for_good_clones(
                    check_clone_data(
                        get_clones(expected_number_of_clones=1866)
                    )
                )
            )
        )

def write_to_tsv(data, filename):
    with open(filename, "w", newline="") as f:
        writer = DictWriter(f, fieldnames=data[0].keys(), delimiter="\t")
        writer.writeheader()
        for datum in data:
            writer.writerow(datum)

