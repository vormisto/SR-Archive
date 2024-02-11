# Create lambda function using the module
module "lambda_scan" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_scan_iam_policy_doc
    lambda = var.lambda_scan
    environment_variables = ({
        region = var.aws_region,
        table_name = var.apartments_table_name,
        queue_url = aws_sqs_queue.sqs_queue.url,
        GSI = var.apartments_table_name_index
    })
}

# Access to DynamoDB GSI and SQS
data "aws_iam_policy_document" "lambda_scan_iam_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:Query"]
    resources = ["${module.apartments_table.table.arn}/index/${var.apartments_table_name_index}"]
  }
  statement {
    effect = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_queue.arn]
  }
  depends_on = [module.apartments_table.table]
}

# Create EventBridge schedule to run lambda function at specific time once a day
module "lambda_scan_eventbridge" {
    source = "./modules/eventbridge_schedule"
    function_name = module.lambda_scan.function.function_name
    function_arn = module.lambda_scan.function.arn
    schedule_expression = "cron(0 ${var.scan_hour} * * ? *)"
}