# Create lambda function using the module
module "lambda_api" {
    source = "./modules/lambda"
    build_dir = var.build_dir
    application_name = var.application_name
    iam_policy_document = data.aws_iam_policy_document.lambda_api_iam_policy_doc
    lambda = var.lambda_api
    environment_variables = ({
        region = var.aws_region,
        table_name = var.apartments_table_name,
        scan_hour = var.scan_hour
    })
}

# Read only access to DynamoDB
data "aws_iam_policy_document" "lambda_api_iam_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:Query"]
    resources = [module.apartments_table.table.arn]
  }
}