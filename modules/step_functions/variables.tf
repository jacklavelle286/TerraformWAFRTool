variable "state_machine_name" {
  type        = string
  description = "The name of the Step Functions state machine."
}

variable "execution_role_arn" {
  type        = string
  description = "The IAM role ARN that Step Functions will assume."
}

variable "definition_json" {
  type        = string
  description = "The JSON definition of the state machine."
}

variable "logging_level" {
  type        = string
  description = "The logging level for the state machine."
  default     = "ALL"
}

variable "include_execution_data" {
  type        = bool
  description = "Whether execution data is included in CloudWatch logs."
  default     = true
}
