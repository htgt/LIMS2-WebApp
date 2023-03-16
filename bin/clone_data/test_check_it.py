from unittest import TestCase

import responses

from check_it import check_clone_data

class TestCheckCloneData(TestCase):
    @responses.activate
    def test_for_good_data(self):
        plate_name = "FP1"
        well_name = "A01"
        json_data = {"miseq_data": {"some": "miseq_data"}}
        responses.get(
            f"http://localhost:8081/public_reports/well_genotyping_info/{plate_name}/{well_name}",
            json=json_data,
        )
        clone_data = [{"plate_name": plate_name, "well_name": well_name}]

        results = check_clone_data(clone_data)

        with self.subTest(msg="Has a single result."):
            self.assertEqual(len(results), 1)

        with self.subTest(msg="Has correct json data."):
            self.assertEqual(results[0].json_data, json_data)

        with self.subTest(msg="Error attribute is None."):
            self.assertEqual(results[0].error, None)


        
