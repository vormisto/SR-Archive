# Create cloudfront distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # S3 origin
  origin {
    origin_id                = "S3_frontend"
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access_control.id
  }

  # APIGW origin
  origin {
    origin_id   = "API_backend"
    domain_name = "${module.api_gateway.api-id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_path = "/${var.application_name}"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Caching settings for S3 origin
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3_frontend"
    cache_policy_id  = data.aws_cloudfront_cache_policy.cloudfront_cache_policy_caching_optimized.id
    viewer_protocol_policy = "redirect-to-https"
  }

  # Caching settings for APIGW origin
  ordered_cache_behavior {
    path_pattern     = "/search*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "API_backend"
    cache_policy_id = aws_cloudfront_cache_policy.cloudfront_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cloudfront_origin_request_policy_all_viewer_except_host_header.id
    viewer_protocol_policy = "https-only" # APIGW accepts only HTTPS
  }

  # Specify price class for cloudfront
  price_class = var.cloudfront_price_class

  # Setup optional geo restriction
  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geoblock
      locations        = var.cloudfront_geoblock_countries
    }
  }

  # Set domain
  aliases = var.custom_domain_enabled ? [var.cloudfront_domain] : []

  # Specify custom cert if custom domain is used, otherwise use the default aws cert
  viewer_certificate {
    acm_certificate_arn            = length(aws_acm_certificate.cloudfront_cert) > 0 ? aws_acm_certificate.cloudfront_cert[0].arn : null
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.custom_domain_enabled ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !var.custom_domain_enabled
  }
}

# Create certificate
resource "aws_acm_certificate" "cloudfront_cert" {
  count             = var.custom_domain_enabled ? 1 : 0
  provider          = aws.acm
  domain_name       = var.cloudfront_domain
  validation_method = "DNS"
}

# Validate the certicate
resource "aws_acm_certificate_validation" "acm_certification_validation" {
  count = var.custom_domain_enabled ? 1 : 0
  provider          = aws.acm
  certificate_arn = aws_acm_certificate.cloudfront_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record_acm_validation : record.fqdn if var.custom_domain_enabled]
}


# Custom cache policy for APIGW
resource "aws_cloudfront_cache_policy" "cloudfront_cache_policy" {
  name        = "${var.application_name}_cloudfront_cache_policy_apigw"
  comment     = "Cache policy for APIGW"
  default_ttl = 1800
  max_ttl     = 86400
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = var.api_querystrings
      }
    }
  }
}

# OAC
resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access_control" {
  name                              = "${var.application_name}_oac"
  description                       = "Cloudfront access to bucket ${var.s3_bucket_frontend}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Get the AWS managed cache policy
data "aws_cloudfront_cache_policy" "cloudfront_cache_policy_caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Get the AWS managed origin request policy
data "aws_cloudfront_origin_request_policy" "cloudfront_origin_request_policy_all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}