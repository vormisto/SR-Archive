variable "table_name" {
  type = string
}

variable "hash_key" {
  type = string
}

variable "hash_key_type" {
  type = string
  default = "S"
}

variable "range_key" {
  type = string
}

variable "range_key_type" {
  type = string
  default = "S"
}

variable "read_capacity_min" {
  type = number
  default = 1
}

variable "write_capacity_min" {
  type = number
  default = 1
}

variable "read_capacity_max" {
  type = number
  default = 10
}

variable "write_capacity_max" {
  type = number
  default = 10
}

variable "target_value" {
  type = number
  default = 70.0
}

variable "gsis" {
  description = "Global Secondary Index configurations"
  type = map(object({
    name = string
    hash_key            = string
    range_key           = string
    projection_type     = string
    non_key_attributes  = list(string)
    read_capacity_min   = number
    read_capacity_max   = number
    write_capacity_min  = number
    write_capacity_max  = number
    auto_scaling        = bool
  }))
  default = {}
}

variable "auto_scaling" {
  type = bool
  default = true
}