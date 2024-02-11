# Create SQS queue for apartments to check
resource "aws_sqs_queue" "sqs_queue" {
  name_prefix = "${var.application_name}_"
  visibility_timeout_seconds = 3600
  message_retention_seconds = 7200
}

# Create SQS queue for logs
resource "aws_sqs_queue" "sqs_queue_logs" {
  name_prefix = "${var.application_name}_logs_"
  visibility_timeout_seconds = 120
  message_retention_seconds = "${var.alarm_frequency * 60 * 2}"
}