from collections import namedtuple
from csv import DictReader
from time import sleep

from requests import get, ConnectionError, JSONDecodeError
from jsonschema import validate as validate_json_schema, ValidationError as SchemaValidationError

class CloneDataError(object):
    """Base error.

    Errors in this case are not exceptions.
    """

class Non200HTMLStatus(CloneDataError):
    def __init__(self, status_code):
        self.status_code = status_code

class NotJSONData(CloneDataError):
    pass

Result = namedtuple("Result", ["clone_name", "json_data", "error"])


if __name__ == "__main__":
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

    with open("list_of_clones_12_01_23.tsv", newline='') as f:
        clones = DictReader(f, delimiter='\t')
        results = []
        for n, clone in enumerate(clones):
            json_data = error = None
            response = get(
                f"http://localhost:8081/public_reports/well_genotyping_info/{clone['plate_name']}/{clone['well_name']}",
                headers={"accept": "application/json"},
            )
            if response.status_code == 200:
                try:
                    json_data = response.json()
                    try:
                        validate_json_schema(
                            json_data,
                            {
                                "type": "object",
                                "properties": {
                                    "miseq_data": {"type": "object"},
                                },
                            },
                        )
                    except SchemaValidationError as e:
                        error = e
                except JSONDecodeError:
                    error = NotJSONData()
            else:
                error = Non200HTMLStatus(status_code=response.status_code)
            results.append(
                Result(
                    clone_name=clone["plate_name"]+"_"+clone["well_name"],
                    json_data=json_data,
                    error=error,
                )
            )
    good_clones = [result for result in results if result.error is None]
    clones_with_non_200_http_status = [result.clone_name for result in results if isinstance(result.error, Non200HTMLStatus)]
    clones_with_non_json_result = [result.clone_name for result in results if isinstance(result.error, NotJSONData)]
    clones_with_missing_miseq_data = [result.clone_name for result in results if isinstance(result.error, SchemaValidationError)]
    print("Total number of clones: ", len(results))
    print("Total number of 'good' clones: ", len(good_clones))
    print(f"Clones with non-200 HTTP status ({len(clones_with_non_200_http_status)}): {clones_with_non_200_http_status}")
    print(f"Clones with non-JSON result (probably due to being pipeline I) ({len(clones_with_non_json_result)}): , {clones_with_non_json_result}")
    print(f"Clones with missing miseq data ({len(clones_with_missing_miseq_data)}): {clones_with_missing_miseq_data}")
