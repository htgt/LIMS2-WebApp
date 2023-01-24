from collections import namedtuple
from csv import DictReader
from time import sleep

from requests import get, ConnectionError

# Check that the server is up and running.
for t in range(60):
    try:
        get("http://localhost:8081")
    except ConnectionError:
        sleep(1)
        if t == 59:
            raise
    else:
        break

Result = namedtuple("Result", ["clone_name", "response_status"])

with open("list_of_clones_12_01_23.tsv", newline='') as f:
    clones = DictReader(f, delimiter='\t')
    results = []
    for n, clone in enumerate(clones):
        if n % 100 == 0:
            print(n)
        response = get("http://localhost:8081/public_reports/well_genotyping_info/{plate}/{well}".format(plate=clone["plate_name"], well=clone["well_name"]))
        results.append(Result(clone_name=clone["plate_name"]+"_"+clone["well_name"], response_status=response.status_code))

print("Total number of clones: ", len(results))
print("Total number of 'good' clones: ", len([result for result in results if result.response_status == 200]))
