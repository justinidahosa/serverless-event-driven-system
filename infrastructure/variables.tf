variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "serverless-event-driven-system"
}

variable "api_lambda_filename" {
  description = "Path to API Lambda zip (created before terraform apply)"
  type        = string
  default     = "../lambdas/api_handler.zip"
}

variable "worker_lambda_filename" {
  description = "Path to Worker Lambda zip (created before terraform apply)"
  type        = string
  default     = "../lambdas/worker.zip"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}
