resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  hash_key       = var.hash_key
  range_key      = var.range_key
  read_capacity  = var.read_capacity_min
  write_capacity = var.write_capacity_min

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  attribute {
    name = var.range_key
    type = var.range_key_type
  }

  dynamic "global_secondary_index" {
    for_each = var.gsis
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = global_secondary_index.value.read_capacity_min
      write_capacity     = global_secondary_index.value.write_capacity_min
    }
  }

}

resource "aws_appautoscaling_target" "read_target" {
  count = var.auto_scaling ? 1 : 0
  max_capacity       = var.read_capacity_max
  min_capacity       = var.read_capacity_min
  resource_id        = "table/${aws_dynamodb_table.table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "write_target" {
  count = var.auto_scaling ? 1 : 0
  max_capacity       = var.write_capacity_max
  min_capacity       = var.write_capacity_min
  resource_id        = "table/${aws_dynamodb_table.table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count = var.auto_scaling ? 1 : 0
  name               = "${var.table_name}_DynamoDBReadCapacityAutoscalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.target_value
  }
}

resource "aws_appautoscaling_policy" "write_policy" {
  count = var.auto_scaling ? 1 : 0
  name               = "${var.table_name}_DynamoDBWriteCapacityAutoscalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.target_value
  }
}

resource "aws_appautoscaling_target" "gsi_read_target" {
  for_each = { for idx, gsi in var.gsis : idx => gsi if gsi.auto_scaling }

  max_capacity       = each.value.read_capacity_max
  min_capacity       = each.value.read_capacity_min
  resource_id        = "table/${aws_dynamodb_table.table.name}/index/${each.value.name}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "gsi_write_target" {
  for_each = { for idx, gsi in var.gsis : idx => gsi if gsi.auto_scaling }

  max_capacity       = each.value.write_capacity_max
  min_capacity       = each.value.write_capacity_min
  resource_id        = "table/${aws_dynamodb_table.table.name}/index/${each.value.name}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "gsi_read_policy" {
  for_each = { for idx, gsi in var.gsis : idx => gsi if gsi.auto_scaling }

  name               = "${each.value.name}_read"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_read_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_read_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_read_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "gsi_write_policy" {
  for_each = { for idx, gsi in var.gsis : idx => gsi if gsi.auto_scaling }

  name               = "${each.value.name}_write"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_write_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_write_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_write_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70
  }
}
