variable "email_address" {
  description = "The email address to subscribe to the SNS topic"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_address))
    error_message = "The email_subscription variable must be a valid email address."
  }
}
