import unittest
import json
from unittest.mock import patch
from lambdas.get_gates.lambda_handler import lambda_handler


class TestGetGatesLambdaHandler(unittest.TestCase):
    @patch('lambdas.get_gates.lambda_handler.get_gates')
    def test_lambda_handler_success(self, mock_get_gates):
        mock_gates = {
                    "result": [
                        [
                            "ALD",
                            "Aldermain",
                            "[{\"hu\": \"200\", \"id\": \"SOL\"}, {\"hu\": \"160\", \"id\": \"ALS\"}, {\"hu\": \"320\", \"id\": \"VEG\"}]"
                        ],
                        [
                            "ALS",
                            "Alshain",
                            "[{\"hu\": \"1\", \"id\": \"ALT\"}, {\"hu\": \"1\", \"id\": \"ALD\"}]"
                        ]
                    ]
                }

        mock_get_gates.return_value = mock_gates
        event = {}
        context = {}

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(json.loads(response['body'])['result'], mock_gates)

    @patch('lambdas.get_gates.lambda_handler.get_gates')
    def test_lambda_handler_exception(self, mock_get_gates):
        mock_get_gates.side_effect = Exception("Database Error")
        event = {}
        context = {}

        response = lambda_handler(event, context)

        self.assertEqual(response['statusCode'], 500)
        self.assertIn("Database Error", json.loads(response['body'])['error'])


if __name__ == '__main__':
    unittest.main()
