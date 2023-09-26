from csv import DictWriter
from check_it import check_clone_data
from clone_data_fixer_upper import init
from analyse_it import convert_alphanumeric_well_name_to_numeric as to_numeric
init("lims2:team87@htgt-db.internal.sanger.ac.uk:5440/lims2_clone_data")
from clone_data_fixer_upper import get_clones
clones = get_clones(expected_number_of_clones=1866)
def get_relevant_data(data):
    return {
        "fp_plate": data["plate_name"],
        "fp_well": data["well_name"],
        "miseq_plate": data["miseq"]["data"]["miseq_plate"],
        "miseq_well": to_numeric(data["miseq"]["data"]["miseq_well"]),
        "miseq_experiment": data["miseq"]["data"]["experiment_name"]
    }
    
def filter_results_data_for_good_clones(results):
    return [
        result.json_data for result in results if result.error is None
    ]
    
def transform_to_relevant_data(data):
    return [
        get_relevant_data(datum) for datum in data
    ]
    
def order_by_fp(data):
    return sorted(data, key=lambda d: (d["fp_plate"], d["fp_well"]))
    
def get_all_relevant_good_clone_data():
    return order_by_fp(
            transform_to_relevant_data(
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

