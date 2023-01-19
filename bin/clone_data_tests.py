from collections import namedtuple
from csv import DictReader

from requests import get

response = get("http://localhost:8004")

Result = namedtuple("Result", ["clone_name", "response_status"])

with open("list_of_clones_12_01_23.tsv") as f:
    clones = DictReader(f, delimiter='\t')
    results = []
    for clone in clones:
        response = get("http://localhost:8004/public_reports/well_genotyping_info/{plate}/{well}".format(plate=clone["plate_name"], well=clone["well_name"]))
        results.append(Result(clone_name=clone["plate_name"]+"_"+clone["well_name"], response_status=response.status_code))

print("Total number of clones: ", len(results))
print("Total number of 'good' clones: ", len([result for result in results if result.response_status == 200]))
