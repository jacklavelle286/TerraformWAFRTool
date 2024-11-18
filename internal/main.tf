data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# eventbride to capture customer WAFR tool information

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
  policy_blocks =  [
    {sid = "Step functions"
      effect = "Allow"
      actions = ["states:StartExecution"]
      resources = [var.step_function_arn]
    }
  ]
}




# lambda functions

# Get Risks Function

module "get_risks_function" {
  source = "../modules/lambda_function"
  filename = "../modules/lambda_function/code/getriskfunction.zip"
  source_file = "../modules/lambda_function/code/getriskfunction.py"
  output_path = "../modules/lambda_function/code/getriskfunction.zip"
  handler_name = "getrisklambda_handler"
  function_name = "get_risks_function"
  lambda_role_arn = module.get_risks_role.rule_role_arn
  environment_variables = {
    DYNAMODB_TABLE = "myddbtable" # placeholder
  }
}

module "get_risks_role" {
  source = "../modules/iam_role"
  role_name = "get_risks_role"
  assume_role_service = "lambda"
  policy_blocks =  [
    {
      sid = "Well Architected"
      effect = "Allow"
      actions = ["wellarchitected:GetLensReviewReport", "wellarchitected:GetWorkload", "wellarchitected:ListAnswers" ]
      resources = ["*"]
    },
    {
      sid = "DynamoDB"
      effect = "Allow"
      actions = ["dynamodb:PutItem"]
      resources = ["arn:aws:dynamodb:eu-west-2:590183835826:table/myddbtable"] # placeholder
    },
    {
      sid = "Cloudwatch Logs"
      effect = "Allow"
      actions = ["logs:CreateLogGroup"]
      resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    },
    {
      sid = "Cloudwatch Logs"
      effect = "Allow"
      actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["*"]
    }
  ]
  
}