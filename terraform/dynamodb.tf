# Create table for data for listing data
module "apartments_table" {
  source = "./modules/dynamodb"
  table_name = var.apartments_table_name
  hash_key = "type"
  range_key = "cityId"
  read_capacity_min = 2
  write_capacity_min = 2
  read_capacity_max = 15
  write_capacity_max = 10
  target_value = 70.0
  auto_scaling = true
  gsis = {
    "ForChecking": {
      name                = var.apartments_table_name_index
      hash_key            = "type"
      range_key           = "cityId"
      projection_type     = "INCLUDE"
      non_key_attributes  = ["type", "cityId"]
      read_capacity_min   = 2
      read_capacity_max   = 10
      write_capacity_min  = 2
      write_capacity_max  = 10
      auto_scaling        = false
    }
  }
}