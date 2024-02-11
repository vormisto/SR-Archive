# Fetch zone info
data "aws_route53_zone" "route53_zone" {
  count        = var.custom_domain_enabled ? 1 : 0
  name         = var.route53_hosted_domain
  private_zone = false
}

# Create A record
resource "aws_route53_record" "route53_record" {
  count   = var.custom_domain_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.route53_zone[0].zone_id
  name    = var.cloudfront_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# This is used to verify the domain to get certification
resource "aws_route53_record" "route53_record_acm_validation" {
  for_each = var.custom_domain_enabled && length(aws_acm_certificate.cloudfront_cert) > 0 ? {
    for dvo in aws_acm_certificate.cloudfront_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone[0].zone_id
}