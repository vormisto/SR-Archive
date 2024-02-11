# Create SNS topic
resource "aws_sns_topic" "sns_topic" {
  name = "${var.application_name}_sns_topic"
}

# Add email to SNS topic
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}