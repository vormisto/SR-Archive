# https://registry.terraform.io/providers/hashicorp/aws/2.34.0/docs/guides/serverless-with-aws-lambda-and-api-gateway

resource "aws_api_gateway_rest_api" "api_gateway_rest_api" {
  name        = "${var.application_name}_rest_api"
  description = "API for application ${var.application_name}"
  endpoint_configuration {
    types = [var.endpoint_type]
  }
}

resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  parent_id   = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  path_part   = var.endpoint_path
}

resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_rest_api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = var.endpoint_method
  authorization = "NONE"

  request_parameters = var.required_querystrings

  request_validator_id = aws_api_gateway_request_validator.api_gateway_request_validator.id
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  resource_id = aws_api_gateway_method.api_gateway_method.resource_id
  http_method = aws_api_gateway_method.api_gateway_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.api_gateway_integration, aws_api_gateway_method.api_gateway_method]

  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  stage_name  = var.application_name
}

resource "aws_lambda_permission" "api_gateway_lambda-permission" {
  statement_id  = "${var.application_name}_api_gateway_lambda_permission"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*/*"
}

resource "aws_api_gateway_request_validator" "api_gateway_request_validator" {
  name = "${var.application_name}_api_gateway_request_validator"
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  validate_request_parameters = true
}