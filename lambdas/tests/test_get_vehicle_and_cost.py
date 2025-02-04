import unittest
import json
from unittest.mock import patch
from lambdas.get_vehicle_and_cost.lambda_handler import lambda_handler


class TestGetVehicleAndCostLambdaHandler(unittest.TestCase):
    @patch('lambdas.get_vehicle_and_cost.lambda_handler.CostCalculator')
    @patch('lambdas.get_vehicle_and_cost.lambda_handler.logger')
    def test_lambda_handler_personal_vehicle_cheaper(self, mock_logger, mock_cost_calculator):
        mock_cost_calculator.calculate_personal_cost.return_value = 35.0
        mock_cost_calculator.calculate_hstc_cost.return_value = 50.0

        event = {
            "pathParameters": {
                "distance": "100"
            },
            "queryStringParameters": {
                "passengers": "2",
                "parking": "3"
            }
        }
        context = {}

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['cost'], 35.0)
        self.assertEqual(body['vehicle'], "Personal Vehicle")

    @patch('lambdas.get_vehicle_and_cost.lambda_handler.CostCalculator')
    @patch('lambdas.get_vehicle_and_cost.lambda_handler.logger')
    def test_lambda_handler_hstc_vehicle_cheaper_when_cost_is_equal(self, mock_logger, mock_cost_calculator):
        mock_cost_calculator.calculate_personal_cost.return_value = 50.0
        mock_cost_calculator.calculate_hstc_cost.return_value = 50.0

        event = {
            "pathParameters": {
                "distance": "100"
            },
            "queryStringParameters": {
                "passengers": "2",
                "parking": "3"
            }
        }
        context = {}

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['cost'], 50.0)
        self.assertEqual(body['vehicle'], "HSTC Vehicle")

    @patch('lambdas.get_vehicle_and_cost.lambda_handler.CostCalculator')
    @patch('lambdas.get_vehicle_and_cost.lambda_handler.logger')
    def test_lambda_handler_exception(self, mock_logger, mock_cost_calculator):
        mock_cost_calculator.calculate_personal_cost.side_effect = Exception("Calculation Error")
        event = {
            "pathParameters": {
                "distance": "100"
            },
            "queryStringParameters": {
                "passengers": "2",
                "parking": "3"
            }
        }
        context = {}

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 500)
        self.assertIn("Route search failed", json.loads(response['body'])['error'])


if __name__ == '__main__':
    unittest.main()
