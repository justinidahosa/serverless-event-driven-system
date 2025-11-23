output "api_invoke_url" {
  description = "Invoke URL for the API POST /items"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/items"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.main_queue.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.items.name
}
output "api_url" {
  description = "Invoke URL for the API POST /items"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/items"
}
output "sqs_dlq_url" {
  description = "URL for the worker DLQ"
  value       = aws_sqs_queue.worker_dlq.id
}

output "sqs_dlq_arn" {
  description = "ARN for the worker DLQ"
  value       = aws_sqs_queue.worker_dlq.arn
}
output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.pool.id
}

output "client_id" {
  description = "Cognito User Pool Client ID (no secret client)"
  value       = aws_cognito_user_pool_client.client.id
}