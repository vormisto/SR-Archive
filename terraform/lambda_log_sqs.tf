# Create lambda function using the module
module "lambda_log_sqs" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_log_sqs_iam_policy_doc
    lambda = var.lambda_log_sqs
    environment_variables = ({
      queue_url = aws_sqs_queue.sqs_queue_logs.url
    })
}

# Access to logs and SQS
data "aws_iam_policy_document" "lambda_log_sqs_iam_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["logs:Describe*", "logs:FilterLogEvents", "logs:GetLogEvents"]
    resources = ["${module.lambda_fetch.log_group.arn}:*", "${module.lambda_check.log_group.arn}:*", "${module.lambda_api.log_group.arn}:*", "${module.lambda_scan.log_group.arn}:*"]
  }
  statement {
    effect = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_queue_logs.arn]
  }
  depends_on = [module.lambda_fetch.log_group]
}

# Monitor lambda function "fetch" logs
module "lambda_fetch_filter" {
    source = "./modules/log_subscription_filter"
    lambda = module.lambda_log_sqs.function
    log_group = module.lambda_fetch.log_group
    name = "fetch"
}

# Monitor lambda function "api" logs
module "lambda_api_filter" {
    source = "./modules/log_subscription_filter"
    lambda = module.lambda_log_sqs.function
    log_group = module.lambda_api.log_group
    name = "api"
}

# Monitor lambda function "check" logs
module "lambda_check_filter" {
    source = "./modules/log_subscription_filter"
    lambda = module.lambda_log_sqs.function
    log_group = module.lambda_check.log_group
    name = "check"
}

# Monitor lambda function "scan" logs
module "lambda_scan_filter" {
    source = "./modules/log_subscription_filter"
    lambda = module.lambda_log_sqs.function
    log_group = module.lambda_scan.log_group
    name = "scan"
}