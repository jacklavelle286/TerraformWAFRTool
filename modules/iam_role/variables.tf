variable "assume_role_service" {
  type = string
  default = "events"
}

variable "policy_choice" {
  type = string
  default = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.policy_choice)
    error_message = "Must be allow or Deny"  
  }
}

variable "policy_service" {
  type = string
}

variable "api_call" {
  type = string
}
variable "resource" {
  type = string

}


variable "role_name" {
  type = string
}