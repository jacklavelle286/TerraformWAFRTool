data "aws_caller_identity" "current" {}
data "aws_region" "current" {}




module "internal_eventbridge" {
  source              = "../modules/eventbridge"
  rule_name           = "pass-to-step-function"
  customer_account_id = var.customer_account_id
  target_arn          = var.step_function_arn
  event_pattern       = var.recieve_event_pattern
  event_bus_name = var.event_bus_name
  rule_role_arn       = module.eventbridge_role.rule_role_arn
  event_bus_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCustomerAccountPutEvents",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.customer_account_id}:role/${var.cross-account-wafr-role}"
        },
        "Action" : "events:PutEvents",
        "Resource" : "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}"
      }
    ]
  })
}


module "eventbridge_role" {
  role_name = "eventbride-role"
  source = "../modules/iam_role"
  assume_role_service = "events"
  policy_choice = "Allow"
  policy_service = "states"
  api_call = "StartExecution"
  resource = var.step_function_arn
}