# CloudWatch Alarm for Worker Lambda errors
resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  alarm_name          = "${var.project_name}-worker-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm if Worker Lambda has any errors"
  dimensions = {
    FunctionName = aws_lambda_function.worker.function_name
  }
}
# CloudWatch Alarm if messages are stuck in the queue
resource "aws_cloudwatch_metric_alarm" "sqs_backlog" {
  alarm_name          = "${var.project_name}-sqs-backlog"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "Alarm if more than 10 messages are waiting in SQS"
  dimensions = {
    QueueName = aws_sqs_queue.main_queue.name
  }
}
resource "aws_sns_topic" "dlq_alert" {
  name = "${var.project_name}-dlq-alert"
}
resource "aws_sns_topic_subscription" "dlq_email" {
  topic_arn = aws_sns_topic.dlq_alert.arn
  protocol  = "email"
  endpoint  = "justinidahosa@gmail.com"
}
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-dlq-messages"
  alarm_description   = "Alarm when DLQ has any visible messages"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    QueueName = aws_sqs_queue.worker_dlq.name
  }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.dlq_alert.arn]
}
