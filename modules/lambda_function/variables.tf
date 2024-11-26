variable "handler_name" {
  type = string
  description = "handler name for the lambda function"
}

variable "function_name" {
  type = string
  description = "lambda function name"
}

variable "lambda_role_arn" {
  type = string
  description = "lambda function role arn"
}

variable "source_file" {
  type = string
  description = "source file for our function"
}

variable "output_path" {
  type = string
  description = "zipped version of the lambda function"
}

variable "runtime" {
  type = string
  description = "run time of the function"
  default = "python3.12"
}

variable "filename" {
  description = "zipped filename"

}

variable "environment_variables" {
  type = map(string)
  description = "Environment variables for the Lambda function"
}

variable "timeout" {
  type = number
  default = 3
}

variable "lambda_layers" {
  type        = list(string)
  description = "Optional Lambda layers to attach to the function"
  default     = [] # Default to an empty list
}


variable "memory_size" {
  type = number
  default = 128
}