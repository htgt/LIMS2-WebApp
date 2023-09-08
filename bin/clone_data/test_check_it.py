from unittest import TestCase

import responses

from check_it import (
    check_clone_data,
    Clone,
    KnownMissingMiseqData,
    NotJSONData,
    Non200HTMLStatus,
    SchemaValidationError
)

class TestCheckCloneData(TestCase):
    @responses.activate
    def test_for_good_data(self):
        plate_name = "FP1"
        well_name = "A01"
        json_data = {"miseq": {"data": {"one": "thing", "another": "thing"}}}
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            json=json_data,
        )
        clone_data = [Clone(plate=plate_name, well=well_name)]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct clone name."):
            self.assertEqual(results[0].clone_name, plate_name+"_"+well_name)

        with self.subTest(msg="Has correct json data."):
            self.assertEqual(results[0].json_data, json_data)

        with self.subTest(msg="Error attribute is None."):
            self.assertEqual(results[0].error, None)

    @responses.activate
    def test_for_expected_missing_miseq_data(self):
        plate_name = "FP1"
        well_name = "A01"
        json_data = {"miseq": {"error": "woops"}}
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            json=json_data,
        )
        clone_data = [Clone(plate=plate_name, well=well_name)]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct clone name."):
            self.assertEqual(results[0].clone_name, plate_name+"_"+well_name)

        with self.subTest(msg="Has correct json data."):
            self.assertEqual(results[0].json_data, json_data)

        with self.subTest(msg="Error attribute is KnownMissingMiseqData."):
            print(results[0].error.message)
            self.assertIsInstance(results[0].error, KnownMissingMiseqData)


    @responses.activate
    def test_for_unexpected_missing_miseq_data(self):
        plate_name = "FP1"
        well_name = "A02"
        json_data = {"miseq": None}
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            json=json_data,
        )
        clone_data = [Clone(plate=plate_name, well=well_name)]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct clone name."):
            self.assertEqual(results[0].clone_name, plate_name+"_"+well_name)

        with self.subTest(msg="Has correct json data."):
            self.assertEqual(results[0].json_data, json_data)

        with self.subTest(msg="Has correct error - SchemaValidationError."):
            self.assertIsInstance(results[0].error, SchemaValidationError)

    @responses.activate
    def test_for_failed_requests(self):
        plate_name = "FP1"
        well_name = "A03"
        status_code = 500
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            status=status_code,
        )
        clone_data = [Clone(plate=plate_name, well=well_name)]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct clone name."):
            self.assertEqual(results[0].clone_name, plate_name+"_"+well_name)

        with self.subTest(msg="Has correct error - Non200HTMLStatus."):
            self.assertIsInstance(results[0].error, Non200HTMLStatus)
            self.assertEqual(results[0].error.status_code, status_code)

    @responses.activate
    def test_for_non_json_data(self):
        plate_name = "FP1"
        well_name = "A04"
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            body="<html>Some stuff<\html§>",
        )
        clone_data = [Clone(plate=plate_name, well=well_name)]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct clone name."):
            self.assertEqual(results[0].clone_name, plate_name+"_"+well_name)

        with self.subTest(msg="Has correct error - NotJSONData."):
            self.assertIsInstance(results[0].error, NotJSONData)
