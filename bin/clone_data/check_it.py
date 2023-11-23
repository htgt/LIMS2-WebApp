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

class KnownMissingMiseqData(CloneDataError):
    def __init__(self, message):
        self.message = message

Result = namedtuple("Result", ["clone_name", "json_data", "error"])
Clone = namedtuple("Clone", ["plate", "well"])


def check_the_server_is_up_and_running():
    for t in range(60):
        try:
            get("http://localhost:8081")
        except ConnectionError:
            sleep(1)
            if t == 59:
                raise
        else:
            break


def check_clone_data(clones):
    results = []
    for clone in clones:
        json_data = error = None
        response = get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{clone.plate}/{clone.well}",
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
                                "miseq": {
                                    "type": "object",
                                    "oneOf": [
                                        {
                                            "properties": {"data": {"type": "object"}},
                                            "additionalProperties": False,
                                        },
                                        {
                                            "properties": {"error": {"type": "string", "minLength": 2}},
                                            "additionalProperties": False,
                                        },
                                    ]
                                },
                            },
                        },
                    )
                    try: 
                        error_attribute = json_data["miseq"]["error"]
                    except KeyError:
                        pass
                    else:
                        error = KnownMissingMiseqData(message=error_attribute)
                except SchemaValidationError as e:
                    error = e
            except JSONDecodeError:
                error = NotJSONData()
        else:
            error = Non200HTMLStatus(status_code=response.status_code)
        results.append(
            Result(
                clone_name=clone.plate+"_"+clone.well,
                json_data=json_data,
                error=error,
            )
        )

    return results


def print_clone_data_results(results):
    good_clones = [result for result in results if result.error is None]
    clones_with_known_missing_miseq_data =  [result.clone_name for result in results if isinstance(result.error, KnownMissingMiseqData)]
    clones_with_non_200_http_status = [result.clone_name for result in results if isinstance(result.error, Non200HTMLStatus)]
    clones_with_non_json_result = [result.clone_name for result in results if isinstance(result.error, NotJSONData)]
    clones_with_missing_miseq_data = [result.clone_name for result in results if isinstance(result.error, SchemaValidationError)]
    print("Total number of clones: ", len(results))
    print("Total number of 'good' clones: ", len(good_clones))
    print("Total number of known missing-miseq clones: ", len(clones_with_known_missing_miseq_data))
    print(f"Clones with non-200 HTTP status ({len(clones_with_non_200_http_status)}): {clones_with_non_200_http_status}")
    print(f"Clones with non-JSON result (probably due to being pipeline I) ({len(clones_with_non_json_result)}): , {clones_with_non_json_result}")
    print(f"Clones with missing miseq data ({len(clones_with_missing_miseq_data)}): {clones_with_missing_miseq_data}")
