# SQS DLQ (dead-letter queue)
resource "aws_sqs_queue" "worker_dlq" {
  name = "${var.project_name}-worker-dlq"
}

# Main SQS queue with redrive policy to the DLQ
resource "aws_sqs_queue" "main_queue" {
  name = "${var.project_name}-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.worker_dlq.arn
    maxReceiveCount     = 3
  })
}

# DynamoDB table
resource "aws_dynamodb_table" "items" {
  name         = "${var.project_name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Roles for Lambdas
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic logging permissions for lambdas
resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy to let API Lambda send messages to SQS
resource "aws_iam_role_policy" "api_lambda_sqs_policy" {
  name = "${var.project_name}-api-sqs-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.main_queue.arn
      }
    ]
  })
}

# Worker permissions (SQS read + DynamoDB write)
resource "aws_iam_role_policy" "worker_policy" {
  name = "${var.project_name}-worker-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.main_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.items.arn
      }
    ]
  })
}

# Lambda Functions
resource "aws_lambda_function" "api" {
  filename         = var.api_lambda_filename
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  source_code_hash = filebase64sha256(var.api_lambda_filename)

  environment {
    variables = {
      SQS_URL = aws_sqs_queue.main_queue.id
    }
  }
}

resource "aws_lambda_function" "worker" {
  filename         = var.worker_lambda_filename
  function_name    = "${var.project_name}-worker"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  source_code_hash = filebase64sha256(var.worker_lambda_filename)

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.items.name
    }
  }
}

# Event source mapping: SQS -> worker Lambda (minimal supported for SQS)
resource "aws_lambda_event_source_mapping" "sqs_to_worker" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.worker.arn
  enabled          = true
  batch_size       = 10
}

# API Gateway (REST) -> API Lambda
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api-gw"
}

resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# POST method (expects cognito authorizer present)
resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.api.arn}/invocations"
}

resource "aws_lambda_permission" "api_gw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_proxy]
  rest_api_id = aws_api_gateway_rest_api.api.id
  description = "Deployment for ${var.project_name}"
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "dev"
  description   = "Dev stage"
}
