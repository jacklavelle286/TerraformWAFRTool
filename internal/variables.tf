variable "region" {
  type    = string
  default = "eu-west-2"
}



variable "customer_account_id" {
  type    = string
  default = "050752633066"

}


variable "event_bus_name" {
  description = "The name of the EventBridge event bus."
  type        = string
  default     = "internal_event_bus_01"
}

variable "cross-account-wafr-role" {
  description = "name of the role which is deployed in the customer account"
  type        = string
  default     = "cross-account-wafr-role"
}

variable "recieve_event_pattern" {
  type        = string
  description = "Event pattern to match events received from the Customer Account"

  default = <<EOF
{
  "detail-type": ["AWS API Call via CloudTrail"],
  "source": ["aws.wellarchitected"],
  "detail": {
    "eventSource": ["wellarchitected.amazonaws.com"],
    "requestParameters": {
      "WorkloadId": [{
        "exists": true
      }],
      "MilestoneName": [{
        "exists": true
      }]
    },
    "eventName": ["CreateMilestone"]
  }
}
EOF
}



variable "internal_aws_profile" {
  description = "AWS CLI profile for the internal account"
  type        = string
  default     = "internal-profile"
}


variable "desination_email_address" {
  type = string
}

variable "matplotlib_layer_arn" {
  type = string
}

variable "python_docx_layer_arn" {
  type = string
}

variable "template_file" {
  type = string
}