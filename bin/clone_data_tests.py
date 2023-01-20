from collections import namedtuple
from csv import DictReader
from time import sleep

from requests import get, ConnectionError, JSONDecodeError

class CloneDataError(object):
    """Base error.

    Errors in this case are not exceptions.
    """

class Non200HTMLStatus(CloneDataError):
    def __init__(self, status_code):
        self.status_code = status_code

class NotJSONData(CloneDataError):
    pass

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

Result = namedtuple("Result", ["clone_name", "response_status", "json_data", "error"])

with open("list_of_clones_12_01_23.tsv", newline='') as f:
    clones = DictReader(f, delimiter='\t')
    results = []
    for n, clone in enumerate(clones):
        if n % 100 == 0:
            print(n)
        json_data = error = None
        response = get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{clone['plate_name']}/{clone['well_name']}",
            headers={"accept": "application/json"},
        )
        if response.status_code == 200:
            try:
                json_data = response.json()
            except JSONDecodeError:
                error = NotJSONData()
        results.append(
            Result(
                clone_name=clone["plate_name"]+"_"+clone["well_name"],
                response_status=response.status_code,
                json_data=json_data,
                error=error,
            )
        )

print("Total number of clones: ", len(results))
print("Total number of 'good' clones: ", len([result for result in results if result.response_status == 200]))
