output "api-endpoint" {
  value = module.api_gateway.api-endpoint.invoke_url
}
output "cloudfront" {
    value = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}
output "domain" {
  value = var.custom_domain_enabled ? var.cloudfront_domain : "Custom domain not enabled"
}