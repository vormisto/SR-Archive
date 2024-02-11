output "log_group" {
    value = aws_cloudwatch_log_group.log_group
}
output "function" {
    value = aws_lambda_function.function
}