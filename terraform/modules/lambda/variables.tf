variable "build_dir" {
    type = string
}
variable "application_name" {
    type = string
}
variable "lambda" {
    type = object({
        name = string
        path = string
        runtime = string
        handler = string
        log_retention = number
        timeout = number
    })
}
variable "environment_variables" {}
variable "iam_policy_document" {}
variable "reserved_concurrent_executions" {
    type = number
    default = -1
}