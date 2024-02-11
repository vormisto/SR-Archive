# Create api gateway
module "api_gateway" {
    source = "./modules/api_gateway"
    application_name = var.application_name
    endpoint_type = "REGIONAL"
    endpoint_path = "search"
    endpoint_method = "GET"
    required_querystrings = {
        for x in var.api_querystrings :
        "method.request.querystring.${x}" => true
    }
    lambda_function = module.lambda_api.function
}