output "state_machine_arn" {
  description = "The ARN of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_name" {
  description = "The name of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.log_group.arn
}