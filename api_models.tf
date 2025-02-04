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
        },
        {
          "type": "string"
        },
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


