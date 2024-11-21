variable "assume_role_service" {
  type = string
  default = "events"
}


variable "policy_blocks" {
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  description = "List of policy statement blocks for the role"
}


variable "role_name" {
  type = string
}