resource "aws_sfn_state_machine" "this" {
  name         = var.state_machine_name
  role_arn     = var.execution_role_arn
  definition   = var.definition_json

  logging_configuration {
    level                 = var.logging_level
    include_execution_data = var.include_execution_data
    log_destination       = "${aws_cloudwatch_log_group.log_group.arn}:*"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/states/${var.state_machine_name}-logs"
}
