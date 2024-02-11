# Download requirements for lambda if they exist
resource "null_resource" "requirements" {
  provisioner "local-exec" {
    command = "pip3 install -r ${var.lambda.path}/requirements.txt -t ${var.lambda.path}/"
  }
  count = fileexists("${var.lambda.path}/requirements.txt") ? 1 : 0
}

# Make a zip out of lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${var.lambda.path}"
  output_path = "${var.build_dir}/${var.application_name}-lambda_${var.lambda.name}.zip"
  depends_on = [null_resource.requirements]
}

# Create log group for lambda function
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.lambda.log_retention
}

# Create lambda function
resource "aws_lambda_function" "function" {
   function_name = local.lambda_function_name
   filename = data.archive_file.lambda_zip.output_path
   handler = "${var.lambda.name}.${var.lambda.handler}"
   runtime = var.lambda.runtime
   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
   role = aws_iam_role.iam_role.arn
   timeout = var.lambda.timeout
   reserved_concurrent_executions = var.reserved_concurrent_executions
   depends_on = [data.archive_file.lambda_zip]
   environment {
    variables = var.environment_variables
  }
}

# Create iam role for lambda function
resource "aws_iam_role" "iam_role" {
   name = "${local.lambda_function_name}_role"
   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
}

# Combine passed policy with default CloudWatch logging policy
data "aws_iam_policy_document" "iam_policy_document" {
  source_policy_documents = [var.iam_policy_document.json]
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
  }
}

# Create iam policy with policy document created above
resource "aws_iam_policy" "iam_policy" {
  name        = "${local.lambda_function_name}-policy"
  description = "A policy for lambda function ${local.lambda_function_name}"
  policy      = data.aws_iam_policy_document.iam_policy_document.json
}

# Attach iam policy to iam role
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

# This will be used in resource names
locals {
  lambda_function_name = "${var.application_name}-${var.lambda.name}"
}