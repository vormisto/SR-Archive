# Create lambda function using the module
module "lambda_check" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_check_iam_policy_doc
    lambda = var.lambda_check
    reserved_concurrent_executions = 2
    environment_variables = ({
        region = var.aws_region,
        table_name = var.apartments_table_name,
        domain = var.apartment_listing_website
    })
}

# Access to DynamoDB to get/put/delete items and SQS to read/delete messages
data "aws_iam_policy_document" "lambda_check_iam_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem"]
    resources = [module.apartments_table.table.arn]
  }
  statement {
    effect    = "Allow"
    resources = [aws_sqs_queue.sqs_queue.arn]
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }
  depends_on = [module.apartments_table.table]
}

# Run lambda when message is added to the queue
resource "aws_lambda_event_source_mapping" "lambda_check_event_source_mapping" {
  batch_size        = 1
  event_source_arn  = aws_sqs_queue.sqs_queue.arn
  enabled           = true
  function_name     = module.lambda_check.function.arn
}