# Create EventBridge schedule
resource "aws_cloudwatch_event_rule" "lambda_event_rule" {
  name        = "${var.function_name}_event_rule"
  description = "Trigger lambda function ${var.function_name}"

  schedule_expression = var.schedule_expression
}

# Link EventBridge rule to lamdba
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.lambda_event_rule.name
  target_id = "${var.function_name}_event_target"
  arn       = var.function_arn
}

# Allow EventBridge to run lambda
resource "aws_lambda_permission" "lambda_lambda_permission" {
  statement_id  = "${var.function_name}_lambda_permission"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_event_rule.arn
}