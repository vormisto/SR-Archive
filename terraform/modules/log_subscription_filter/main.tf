# Allow CloudWatch to run lambda function
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "${var.name}_lambda_permission"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda.arn
  principal     = "logs.amazonaws.com"
  source_arn    = "${var.log_group.arn}:*"
}

# Create filter for CloudWatch logs for function
resource "aws_cloudwatch_log_subscription_filter" "log_subscription_filter" {
  name            = "${var.name}_cloudwatch_log_subscription_filter"
  log_group_name  = var.log_group.name
  filter_pattern  = "ERROR"
  destination_arn = var.lambda.arn
}