variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
}

variable "aws_profile" {
  description = "AWS profile to use."
  type    = string
  default = "default"
}

variable "environment" {
  description = "Environment, used as tag"
  type    = string
}

variable "application_name" {
  description = "Name for the application, used in resource names"
  type    = string
}

variable "alarm_email" {
  description = "Email address where the alarms will be sent"
  type    = string
}

variable "alarm_frequency" {
  description = "How often alarm emails are sent in minutes"
  type = number
}

variable "lambda_fetch" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "fetch"
    path = "../lambda/fetch"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 5
  })
}

variable "lambda_log_sns" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "log_sns"
    path = "../lambda/log_sns"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 60
  })
}

variable "lambda_log_sqs" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "log_sqs"
    path = "../lambda/log_sqs"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 3
  })
}

variable "lambda_api" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "api"
    path = "../lambda/api"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 2
  })
}

variable "lambda_check" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "check"
    path = "../lambda/check"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 600
  })
}

variable "lambda_scan" {
  description = "Config values for lambda function"
  type = object({
      name = string
      path = string
      runtime = string
      handler = string
      log_retention = number
      timeout = number
  })
  default = ({
    name = "scan"
    path = "../lambda/scan"
    runtime = "python3.11"
    handler = "lambda_handler"
    log_retention = 3
    timeout = 240
})
}

variable "build_dir" {
    description = "Directory to store temporary lambda build files (zip)"
    type = string
}

variable "apartments_table_name" {
    description = "Name for the dynamodb that contains the listing data"
    type = string 
}

variable "apartments_table_name_index" {
  type = string
  description = "GSI for apartments_table_name"
}

variable "s3_bucket_frontend" {
    description = "Name for S3 bucket to store the frontend files"
    type = string 
}

variable "cloudfront_geoblock" {
  type        = string
  description = "Geoblock setting"
  default = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.cloudfront_geoblock)
    error_message = "Valid values for cloudfront_geoblock are (none, whitelist, blacklist)."
  } 
}

variable "cloudfront_geoblock_countries" {
  type = list
  description = "List of geoblock countries"
  default = ["US"]
}

variable "cloudfront_price_class" {
  type        = string
  description = "Cloudfront price class"
  default = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Valid values for cloudfront_price_class are (PriceClass_All, PriceClass_200, PriceClass_100)."
  } 
}

variable "cloudfront_domain" {
  description = "This is the domain which will point to cloudfront"
  type = string
  default = "test.example.com"
}

variable "route53_hosted_domain" {
  description = "This is the hosted domain where new subdomain (cloudfront_domain) will be created in. Hosted zone has to be setup beforehand"
  type = string
  default = "example.com"
}

variable "api_querystrings" {
  description = "Specify list of querystrings that need to be included for request to be passed to api lambda function"
  type = list
  default = ["city", "type", "from", "to"]
}

variable "custom_domain_enabled" {
  description = "Declare if you want to use custom domain or not. If set true, make sure to setup route53_hosted_domain & cloudfront_domain"
  type    = bool
  default = false
}

variable "scan_hour" {
  type = number
  description = "UTC hour when to start scanning active listings to be checked"
  default = 3
}

variable "apartment_listing_website" {
  type = string
  description = "Domain of the apartment listing website to monitor."
}