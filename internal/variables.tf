variable "region" {
  type    = string
  default = "eu-west-2"
}


variable "step_function_arn" {
  type    = string
  default = "arn:aws:states:eu-west-2:590183835826:stateMachine:MyStateMachine-qjsg9eb39"
}

variable "customer_account_id" {
  type    = string
  default = "992382778815"

}


variable "event_bus_name" {
  description = "The name of the EventBridge event bus."
  type        = string
  default     = "internal_event_bus_01"
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