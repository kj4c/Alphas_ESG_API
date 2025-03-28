provider "aws" {
  region = var.aws_region
}

# S3 Bucket for deployment artifacts
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.lambda_bucket_name
}

# S3 Bucket for RAW DATA
resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "alpha-raw-data-bucket"

  tags = {
    Name        = "JSON Raw Data Storage Bucket"
    Environment = "Dev"
  }
}

# Upload Lambda ZIP file to S3
resource "aws_s3_object" "lambda_zips" {
  for_each = var.lambda_functions

  bucket = var.lambda_bucket_name
  key    = "lambdas/${each.key}.zip"
  source = "backend/${each.key}/lambda.zip"
  
  # forces terraform to detect any zip changes for S3 bucket
  etag = filemd5("backend/${each.key}/lambda.zip")
}

# Lambda Function
resource "aws_lambda_function" "multi_lambda" {
  for_each = var.lambda_functions

  function_name = each.key
  s3_bucket     = var.lambda_bucket_name
  s3_key        = aws_s3_object.lambda_zips[each.key].key
  handler       = each.value.handler
  runtime       = each.value.runtime
  role          = "arn:aws:iam::109471428046:role/LabRole"
  timeout       = 60
  memory_size   = 256

  # makes lambda function redeploy for any changes
  source_code_hash = filebase64sha256("backend/${each.key}/lambda.zip")

  environment {
    variables = {
      FUNCTION_NAME = each.key
    }
  }
  
  layers = [
    "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:28"
  ]
}

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "alpha_api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "PUT", "OPTIONS"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each = var.lambda_functions

  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.multi_lambda[each.key].invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  for_each = var.lambda_functions

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "${each.value.method} /${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# gives the lambda functions permissions
resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = var.lambda_functions

  statement_id  = "${each.key}-AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.multi_lambda[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


terraform {
  backend "s3" {
    bucket = "seng3011-alpha-terraform-state"
    key = "terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-lock"
  }
}