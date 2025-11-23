# Cognito: user pool + client
resource "aws_cognito_user_pool" "pool" {
  name = "${var.project_name}-user-pool"

  # optional but helpful: simple password policy for testing
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = false
  }

  # allow email as username (optional)
  username_attributes = ["email"]
}

# Create a user pool client (no client secret so it's easy to use from CLI/Postman)
resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  # no client secret keeps testing simple
  generate_secret = false

  # allow basic auth flows for password auth via AdminInitiateAuth
  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH"
  ]

  # don't set OAuth for now 
  prevent_user_existence_errors = "ENABLED"
}

# API Gateway authorizer using the Cognito user pool
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name           = "${var.project_name}-cognito-authorizer"
  rest_api_id    = aws_api_gateway_rest_api.api.id
  type           = "COGNITO_USER_POOLS"
  provider_arns  = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"
}
