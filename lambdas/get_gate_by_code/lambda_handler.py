import json
from opt.tools.utils.database import SQLConnection
from opt.tools.utils.queries import GET_GATE_BY_CODE
from opt.tools.utils.logger import logger


def lambda_handler(event, context):
    """AWS Lambda function for /gates/{gateCode}"""
    try:
        path_parameters = event.get("pathParameters", None)

        if not path_parameters:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Missing pathParameters",
                    "received_event": event
                })
            }

        gate_code = path_parameters.get("gateCode")

        if not gate_code:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Missing gateCode in path",
                    "received_event": event
                })
            }

        with SQLConnection() as db:
            gate = db.execute_query(GET_GATE_BY_CODE, (gate_code,))
            logger.info(f"Retrieved gate: {gate}")

        return {
            "statusCode": 200,
            "body": json.dumps({"result": gate[0] if gate else "No gate found"})
        }

    except Exception as e:
        logger.error(f"Database query failed: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Database query failed: {str(e)}"})
        }
