# Create lambda function using the module
module "lambda_log_sns" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_log_sns_iam_policy_doc
    lambda = var.lambda_log_sns
    reserved_concurrent_executions = 1
    environment_variables = ({
      sns_arn = aws_sns_topic.sns_topic.arn
      queue_url = aws_sqs_queue.sqs_queue_logs.url
    })
}

# Access to SQS and SNS for notifications
data "aws_iam_policy_document" "lambda_log_sns_iam_policy_doc" {
  statement {
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = [aws_sns_topic.sns_topic.arn]
  }
  statement {
    effect    = "Allow"
    resources = [aws_sqs_queue.sqs_queue_logs.arn]
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }
}

# Create EventBridge schedule to run lambda function every ${var.alarm_frequency} minutes
module "lambda_log_sns_eventbridge" {
    source = "./modules/eventbridge_schedule"
    function_name = module.lambda_log_sns.function.function_name
    function_arn = module.lambda_log_sns.function.arn
    schedule_expression = "rate(${var.alarm_frequency} minutes)"
}