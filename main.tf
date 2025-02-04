#################################
# Provider & Basic Setup
#################################
provider "aws" {
  region = var.aws_region
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL inbound"
  vpc_id      = var.aws_vpc

  ingress {
    description      = "MySQL inbound"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    #security_groups  = [aws_security_group.lambda_sg.id]
    security_groups  = [var.security_group_id]  
    # Only allow traffic from the Lambda SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

#################################
# RDS MySQL Instance
#################################
resource "aws_db_instance" "mysql" {
  identifier         = "hstc-mysql-db"
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  db_name            = var.db_name
  username           = var.db_username
  password           = var.db_password
  db_subnet_group_name         = var.subnet_group
  skip_final_snapshot          = true
  deletion_protection          = false
  publicly_accessible          = false

  tags = {
    Name = "hstc-mysql-db"
  }
}

#################################
# IAM Role/Policy for Lambda
#################################
resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Inline policy to allow VPC access, logging, etc.
resource "aws_iam_role_policy" "lambda_vpc_policy" {
  name   = "lambda-vpc-policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = data.aws_iam_policy_document.lambda_vpc_policy.json
}

data "aws_iam_policy_document" "lambda_vpc_policy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

#################################
# Lambda Layers
#################################
resource "aws_lambda_layer_version" "third_party" {
  filename   = var.third_party_file
  layer_name = "common-code-layer1"
  compatible_runtimes = ["python3.13"]
}

resource "aws_lambda_layer_version" "utils" {
  filename   = var.utils_file
  layer_name = "common-code-layer2"
  compatible_runtimes = ["python3.13"]
}

#################################
# Lambda Function - get_gates_function
#################################
data "aws_db_instance" "mysql_data" {
  db_instance_identifier = aws_db_instance.mysql.id
  depends_on = [aws_db_instance.mysql]
}

data "aws_db_subnet_group" "existing_subnet_group" {
  name = var.subnet_group
}

data "aws_subnets" "subnets_from_group" {
  filter {
    name   = "subnet-id"
    values = data.aws_db_subnet_group.existing_subnet_group.subnet_ids
  }
}

resource "aws_lambda_function" "get_gates_function" {
  function_name = "get-gates-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.13"

  filename = "${path.module}/build/lambdas/get_gates.zip"
  publish = true

  layers = [
    aws_lambda_layer_version.third_party.arn,
    aws_lambda_layer_version.utils.arn
  ]

  # Provide environment variables for DB connection
  environment {
    variables = {
      DB_HOST     = trimsuffix(data.aws_db_instance.mysql_data.endpoint, ":3306")
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT = var.db_port
    }
  }

  # Configure VPC access so Lambda can reach the private DB 
  vpc_config {
    subnet_ids         = data.aws_subnets.subnets_from_group.ids
    security_group_ids = [var.security_group_id] 
 }

  depends_on = [aws_iam_role_policy.lambda_vpc_policy]
}

###########################################################
# New Lambda Function - get_gate_by_code_function
###########################################################
resource "aws_lambda_function" "get_gate_by_code_function" {
  function_name = "get-gate-by-code-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.13"

  filename = "${path.module}/build/lambdas/get_gate_by_code.zip"

  publish = true

  layers = [
    aws_lambda_layer_version.third_party.arn,
    aws_lambda_layer_version.utils.arn
  ]

  environment {
    variables = {
      DB_HOST     = trimsuffix(data.aws_db_instance.mysql_data.endpoint, ":3306")
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT     = var.db_port
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.subnets_from_group.ids
    security_group_ids = [var.security_group_id]
  }
  depends_on = [aws_iam_role_policy.lambda_vpc_policy]

}

###########################################################################
# New Lambda Function for /gates/{gateCode}/to/{targetGateCode}
###########################################################################
resource "aws_lambda_function" "get_cheapest_route_function" {
  function_name = "get-cheapest-route-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.13"

  filename = "${path.module}/build/lambdas/get_cheapest_route.zip"

  publish = true

  layers = [
    aws_lambda_layer_version.third_party.arn,
    aws_lambda_layer_version.utils.arn
  ]

  environment {
    variables = {
      DB_HOST     = trimsuffix(data.aws_db_instance.mysql_data.endpoint, ":3306")
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT     = var.db_port
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.subnets_from_group.ids
    security_group_ids = [var.security_group_id]
  }

  depends_on = [aws_iam_role_policy.lambda_vpc_policy]
} 

##################################################
# Lambda Function - get_vehicle_and_cost_function
##################################################
resource "aws_lambda_function" "get_vehicle_and_cost_function" {
  function_name = "get-vehicle-and-cost-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.13"

  filename = "${path.module}/build/lambdas/get_vehicle_and_cost.zip"

  publish = true

  layers = [
    aws_lambda_layer_version.third_party.arn,
    aws_lambda_layer_version.utils.arn
  ]

  environment {
    variables = {
      DB_HOST     = trimsuffix(data.aws_db_instance.mysql_data.endpoint, ":3306")
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT     = var.db_port
    }
  }

  # If you need VPC access for any reason (e.g. same as other lambdas)
  vpc_config {
    subnet_ids         = data.aws_subnets.subnets_from_group.ids
    security_group_ids = [var.security_group_id]
  }

  depends_on = [aws_iam_role_policy.lambda_vpc_policy]
}


#################################
# API Gateway (REST) Setup
#################################

# 1) Create the REST API
resource "aws_api_gateway_rest_api" "gates_api" {
  name        = "hstc-challenge-api"
  description = "API for interacting with HSTC endpoints"
}

# 2) Create the /gates resource under the root ("/")
resource "aws_api_gateway_resource" "gates_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_rest_api.gates_api.root_resource_id
  path_part   = "gates"
}

# 3) Create the GET method on /gates
resource "aws_api_gateway_method" "get_gates_method" {
  rest_api_id   = aws_api_gateway_rest_api.gates_api.id
  resource_id   = aws_api_gateway_resource.gates_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# 4) Integrate the GET method with the get_gates_function Lambda function (Lambda Proxy integration)
resource "aws_api_gateway_integration" "get_gates_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.gates_resource.id
  http_method             = aws_api_gateway_method.get_gates_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_gates_function.invoke_arn
}

# Add a method response for the 200 status code
resource "aws_api_gateway_method_response" "gates_get_200" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  resource_id = aws_api_gateway_resource.gates_resource.id
  http_method = aws_api_gateway_method.get_gates_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.gates_response.name
  }
}

# Map the Lambda output to the method response
resource "aws_api_gateway_integration_response" "get_gates_integration_response" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.gates_resource.id
  http_method             = aws_api_gateway_method.get_gates_method.http_method
  status_code             = aws_api_gateway_method_response.gates_get_200.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.get_gates_integration
  ]
}


# 5) Add a child resource under /gates for {gateCode}
resource "aws_api_gateway_resource" "gate_code_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_resource.gates_resource.id
  path_part   = "{gateCode}"
}

# 6) Create a GET method on /gates/{gateCode}
resource "aws_api_gateway_method" "gate_code_get" {
  rest_api_id   = aws_api_gateway_rest_api.gates_api.id
  resource_id   = aws_api_gateway_resource.gate_code_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.gateCode" = true
  }

  # Attach a request validator to validate the parameters.
  request_validator_id = aws_api_gateway_request_validator.param_validator.id
}

# 7) Integrate the GET method with the new "get_gate_by_code_function"
resource "aws_api_gateway_integration" "gate_code_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.gate_code_resource.id
  http_method             = aws_api_gateway_method.gate_code_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_gate_by_code_function.invoke_arn
}


# Create a validator to enforce that required parameters are provided
resource "aws_api_gateway_request_validator" "param_validator" {
  rest_api_id                = aws_api_gateway_rest_api.gates_api.id
  name                       = "params-validator"
  validate_request_parameters = true
  validate_request_body      = false  
}

# Add a method response for the 200 status code
resource "aws_api_gateway_method_response" "gate_code_get_200" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  resource_id = aws_api_gateway_resource.gate_code_resource.id
  http_method = aws_api_gateway_method.gate_code_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.gate_by_code_response.name
  }
}

# Map the Lambda output to the method response
resource "aws_api_gateway_integration_response" "gate_code_integration_200" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.gate_code_resource.id
  http_method             = aws_api_gateway_method.gate_code_get.http_method
  status_code             = aws_api_gateway_method_response.gate_code_get_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

# 8) Add a child resource under /gates/{gateCode}/to
resource "aws_api_gateway_resource" "get_code_to_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_resource.gate_code_resource.id
  path_part   = "to"
}

# 9) Add a child resource under /gates/{gateCode}/to/{targetGateCode}
# /gates/{gateCode}/to/{targetGateCode}
resource "aws_api_gateway_resource" "get_cheapest_route_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_resource.get_code_to_resource.id
  path_part   = "{targetGateCode}"
}

# 10) Create a GET method on /gates/{gateCode}/to/{targetGateCode}
resource "aws_api_gateway_method" "get_cheapest_route_get" {
  rest_api_id   = aws_api_gateway_rest_api.gates_api.id
  resource_id   = aws_api_gateway_resource.get_cheapest_route_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.gateCode"       = true
    "method.request.path.targetGateCode" = true
  }

  request_validator_id = aws_api_gateway_request_validator.param_validator.id
}

# 11) Integrate the GET method with the get_cheapest_route_function
resource "aws_api_gateway_integration" "get_cheapest_code_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.get_cheapest_route_resource.id
  http_method             = aws_api_gateway_method.get_cheapest_route_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_cheapest_route_function.invoke_arn
}


# Add a method response for the 200 status code
resource "aws_api_gateway_method_response" "get_cheapest_route_200" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  resource_id = aws_api_gateway_resource.get_cheapest_route_resource.id
  http_method = aws_api_gateway_method.get_cheapest_route_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.cheapest_route_response.name
  }
}

# Map the Lambda output to the method response
resource "aws_api_gateway_integration_response" "get_cheapest_route_integration_200" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.get_cheapest_route_resource.id
  http_method             = aws_api_gateway_method.get_cheapest_route_get.http_method
  status_code             = aws_api_gateway_method_response.get_cheapest_route_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

# 12) Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_gates_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gates_api.execution_arn}/*/*"
}

# 13) Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw_get_gate_by_code" {
  statement_id  = "AllowAPIGatewayInvokeGetGateByCode"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_gate_by_code_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gates_api.execution_arn}/*/*"
}

# 14) Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw_get_cheapest_route" {
  statement_id  = "AllowAPIGatewayInvokeGetRouteBetweenGates"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_cheapest_route_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gates_api.execution_arn}/*/*"
}

#################################
# API Gateway Resource for /transport
#################################
# 15) Add a child resource under /transport
resource "aws_api_gateway_resource" "transport_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_rest_api.gates_api.root_resource_id
  path_part   = "transport"
}

# 16) Add a child resource under /transport for {distance}
resource "aws_api_gateway_resource" "transport_distance_resource" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  parent_id   = aws_api_gateway_resource.transport_resource.id
  path_part   = "{distance}"
}

# 17) Create a GET method on /transport/{distance}
resource "aws_api_gateway_method" "get_vehicle_and_cost" {
  rest_api_id   = aws_api_gateway_rest_api.gates_api.id
  resource_id   = aws_api_gateway_resource.transport_distance_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    # This makes "{distance}" required
    "method.request.path.distance" = true

    "method.request.querystring.passengers" = true
    "method.request.querystring.parking"    = true
  }
  request_validator_id = aws_api_gateway_request_validator.param_validator.id
}

# Add a method response for the 200 status code
resource "aws_api_gateway_method_response" "get_vehicle_and_cost_200" {
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
  resource_id = aws_api_gateway_resource.transport_distance_resource.id
  http_method = aws_api_gateway_method.get_vehicle_and_cost.http_method
  status_code = "200"

  response_models = {
    "application/json" = aws_api_gateway_model.get_vehicle_and_cost_response.name
  }
}

# Map the Lambda output to the method response
resource "aws_api_gateway_integration_response" "get_vehicle_and_cost_integration_200" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.transport_distance_resource.id
  http_method             = aws_api_gateway_method.get_vehicle_and_cost.http_method
  status_code             = aws_api_gateway_method_response.get_vehicle_and_cost_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

# 18) Integrate the GET method with the get_vehicle_and_cost_function
resource "aws_api_gateway_integration" "get_vehicle_and_cost_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gates_api.id
  resource_id             = aws_api_gateway_resource.transport_distance_resource.id
  http_method             = aws_api_gateway_method.get_vehicle_and_cost.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_vehicle_and_cost_function.invoke_arn
}

# 19) Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw_get_vehicle_and_cost" {
  statement_id  = "AllowAPIGatewayInvokeGetVehicleAndCost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_vehicle_and_cost_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gates_api.execution_arn}/*/*"
}

# Create an API Gatewaydeployment
resource "aws_api_gateway_deployment" "gates_deployment" {
  depends_on = [
      aws_api_gateway_integration.get_gates_integration,
      aws_api_gateway_integration.gate_code_integration,
	    aws_api_gateway_integration.get_cheapest_code_integration,
    	aws_api_gateway_integration.get_vehicle_and_cost_integration
]
  rest_api_id = aws_api_gateway_rest_api.gates_api.id
}

# Create a stage for the API Gateway
resource "aws_api_gateway_stage" "dev_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.gates_api.id
  deployment_id = aws_api_gateway_deployment.gates_deployment.id
}

# Outputs
output "api_invoke_url" {
  value       = "${aws_api_gateway_rest_api.gates_api.execution_arn}/${aws_api_gateway_stage.dev_stage.stage_name}"
  description = "Base URL of the API."
}

