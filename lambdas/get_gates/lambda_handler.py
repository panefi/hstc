import json
from opt.tools.utils.db_utils import get_gates


def lambda_handler(event, context):
    try:
        gates = get_gates()
        return {
            "statusCode": 200,
            "body": json.dumps({"result": gates})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

