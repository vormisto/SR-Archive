# Create lambda function using the module
module "lambda_fetch" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_fetch_iam_policy_doc
    lambda = var.lambda_fetch
    environment_variables = ({
        region = var.aws_region,
        table_name = var.apartments_table_name,
        domain = var.apartment_listing_website
    })
}

# Access to DynamoDB to put items to
data "aws_iam_policy_document" "lambda_fetch_iam_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:PutItem"]
    resources = [module.apartments_table.table.arn]
  }
  depends_on = [module.apartments_table.table]
}

# Create EventBridge schedule for every 30min
module "lambda_fetch_eventbridge" {
    source = "./modules/eventbridge_schedule"
    function_name = module.lambda_fetch.function.function_name
    function_arn = module.lambda_fetch.function.arn
    schedule_expression = "rate(30 minutes)"
}