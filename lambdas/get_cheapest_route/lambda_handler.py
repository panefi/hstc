import json
from opt.tools.utils.db_utils import get_gates
from opt.tools.utils.optimal_route_finder import RouteFinder
from opt.tools.utils.logger import logger


def lambda_handler(event, context):
    """
    AWS Lambda function to find the cheapest route between two gates.
    Example invocation (pathParameters):
      GET /gates/{gateCode}/to/{targetGateCode}
    """
    try:
        path_parameters = event.get("pathParameters", {})
        departure_gate = path_parameters.get("gateCode", "").upper()
        arrival_gate = path_parameters.get("targetGateCode", "").upper()

        if not departure_gate or not arrival_gate:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Missing gateCode or targetGateCode in pathParameters",
                    "received_event": event
                })
            }

        logger.info(f"Finding route from {departure_gate} to {arrival_gate}")
        gate_data = get_gates()

        route_finder = RouteFinder(gate_data)
        result = route_finder.find_cheapest_route(departure_gate, arrival_gate)

        if result["path"]:
            logger.info({"cheapest_route": result["path"], "cost": result["cost"]})
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "cheapest_route": result["path"],
                    "cost": result["cost"]
                })
            }
        else:
            message = f"No route found from {departure_gate} to {arrival_gate}."
            logger.info(message)
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "cheapest_route": [],
                    "cost": float('inf'),
                    "message": message
                })
            }

    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Route search failed: {str(e)}"})
        }
