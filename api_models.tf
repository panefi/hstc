# Successful Response for request to /gates
resource "aws_api_gateway_model" "gates_response" {
  rest_api_id  = aws_api_gateway_rest_api.gates_api.id
  name         = "GatesResponse"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "GatesResponse",
  "type": "object",
  "properties": {
    "result": {
    "type": "array",
    "items": {
      "type": "array",
      "items": [
        {
          "type": "string"
        }
        ]
        }
    }
  },
  "required": ["result"]
}
EOF
}


# Successful Response for request to /gates/{gateCode}
resource "aws_api_gateway_model" "gate_by_code_response" {
  rest_api_id  = aws_api_gateway_rest_api.gates_api.id
  name         = "GateByCodeResponse"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "GateByCodeResponse",
  "type": "object",
  "properties": {
    "result": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["result"]
}
EOF
}


# Successful Response for request to /gates/{gateCode}/to/{targetGateCode}
resource "aws_api_gateway_model" "cheapest_route_response" {
  rest_api_id  = aws_api_gateway_rest_api.gates_api.id
  name         = "CheapestRouteResponse"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "CheapestRouteResponse",
  "type": "object",
  "properties": {
    "cheapest_route": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "cost": {
      "type": "number"
    }
  },
  "required": ["cheapest_route", "cost"]
}
EOF
}


# Successful Response for request to /gates/{gateCode}/to/{targetGateCode}/vehicle
resource "aws_api_gateway_model" "get_vehicle_and_cost_response" {
  rest_api_id  = aws_api_gateway_rest_api.gates_api.id
  name         = "GetVehicleAndCostResponse"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "GetVehicleAndCostResponse",
  "type": "object",
  "properties": {
    "cost": {
      "type": "number"
    },
    "vehicle": {
      "type": "string"
    }
  },
  "required": ["cost", "vehicle"]
}
EOF
}
