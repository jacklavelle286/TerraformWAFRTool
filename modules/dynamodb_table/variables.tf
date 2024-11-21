variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table"
}

variable "hash_key" {
  type        = string
  description = "The primary key hash attribute"
}

variable "hash_key_type" {
  type        = string
  description = "Type of the hash key attribute (S, N, or B)"
  default     = "S"
}

variable "range_key" {
  type        = string
  description = "The primary key range attribute"
}

variable "range_key_type" {
  type        = string
  description = "Type of the range key attribute (S, N, or B)"
  default     = "S"
}

variable "read_capacity" {
  type        = number
  description = "Read capacity units"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units"
  default     = 5
}

variable "additional_attributes" {
  type = list(object({
    name = string
    type = string
  }))
  default = []
}


variable "global_secondary_indexes" {
  type = list(object({
    index_name       = string
    hash_key         = string
    range_key        = optional(string)  # Optional range key for the GSI
    projection_type  = string
    read_capacity    = number
    write_capacity   = number
  }))
  default = []
}
