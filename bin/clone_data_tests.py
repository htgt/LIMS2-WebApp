from requests import get
from csv import DictReader

response = get("http://localhost:8004")

with open("list_of_clones_12_01_23.tsv") as f:
    clones = DictReader(f, delimiter='\t')
    for clone in clones:
        print("Getting data for {plate}{well}".format(plate=clone["plate_name"], well=clone["well_name"]))
        get("http://localhost:8004/public_reports/well_genotyping_info/{plate}/{well}".format(plate=clone["plate_name"], well=clone["well_name"]))

assert response.status_code == 200
