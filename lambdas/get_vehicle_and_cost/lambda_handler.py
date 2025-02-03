import json
from opt.tools.utils.cost_calculation import CostCalculator
from opt.tools.utils.logger import logger


def lambda_handler(event, context):
    """
    AWS Lambda function to determine cheapest vehicle usage (Personal vs HSTC)
    for a given distance (AU), parking days and number of passengers.

    Endpoint format: GET /transport/{distance}?passengers={number}&parking={days}
    - pathParameters: {"distance": "<someNumber>"}
    - queryStringParameters: {"passengers": "<someNumber>", "parking": "<someNumber>"}
    """

    try:
        path_parameters = event.get("pathParameters", {})
        distance = float(path_parameters.get("distance", ""))

        query_params = event.get("queryStringParameters", {})
        days   = int(query_params.get("parking", ""))
        passengers = int(query_params.get("passengers", ""))

        personal_cost = CostCalculator.calculate_personal_cost(distance, days, passengers)
        hstc_cost     = CostCalculator.calculate_hstc_cost(distance, passengers)

        if personal_cost < hstc_cost:
            logger.info({"cost": personal_cost, "vehicle": "Personal Vehicle"})
            result = {"cost": personal_cost, "vehicle": "Personal Vehicle"}
        else:
            logger.info({"cost": hstc_cost, "vehicle": "HSTC Vehicle"})
            result = {"cost": hstc_cost, "vehicle": "HSTC Vehicle"}

        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }

    except Exception as e:
        logger.exception(f"An unexpected error occurred: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Route search failed: {str(e)}"})
        }
