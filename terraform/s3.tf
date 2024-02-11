# Create S3 bucket for frontend
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_frontend
}

# Upload frontend files to S3 bucket
# Source: https://stackoverflow.com/a/76170612
resource "aws_s3_object" "s3_object" {
  for_each = fileset("../frontend/", "**")
  bucket = aws_s3_bucket.s3_bucket.id
  key = each.value
  source = "../frontend/${each.value}"
  etag = filemd5("../frontend/${each.value}")
  content_type = lookup(tomap(local.content_type_map), element(split(".", each.value), length(split(".", each.value)) - 1))
}

# IAM policy to allow cloudfront read access to S3 bucket
data "aws_iam_policy_document" "s3_iam_policy_document" {
  statement {
    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.cloudfront_distribution.arn]
    }
  }
}

# Attach IAM policy to bucket
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.s3_iam_policy_document.json
}

# These are used when uploading files to S3 to ensure content type is set correctly
locals {
  content_type_map = {
   "js" = "application/javascript"
   "html" = "text/html"
   "css"  = "text/css"
  }
}