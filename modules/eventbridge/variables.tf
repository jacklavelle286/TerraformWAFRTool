variable "event_bus_name" {
  type = string
}

variable "event_pattern" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "target_arn" {
  type = string
  
}

variable "rule_role_arn" {
  type = string
}


variable "customer_account_id" {
  type = number

}

variable "event_bus_policy" {
  type = string
  description = "The policy for the custom event bus. If not specified, uses the default policy allowing cross-account access."
}

