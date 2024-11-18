data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# eventbride to capture customer WAFR tool information

module "internal_eventbridge" {
  source              = "../modules/eventbridge"
  rule_name           = "pass-to-step-function"
  customer_account_id = var.customer_account_id
  target_arn          = var.step_function_arn
  event_pattern       = var.recieve_event_pattern
  event_bus_name      = var.event_bus_name
  rule_role_arn       = module.eventbridge_role.role_arn
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
  role_name           = "eventbride-role"
  source              = "../modules/iam_role"
  assume_role_service = "events"
  policy_blocks = [
    { sid       = "Step functions"
      effect    = "Allow"
      actions   = ["states:StartExecution"]
      resources = [var.step_function_arn]
    }
  ]
}


# dynamodb table

module "dynamodb_table" {
  source         = "../modules/dynamodb_table"
  table_name     = "wellarchitectedanswers"
  hash_key       = "WorkloadId"
  range_key      = "QuestionId"
  hash_key_type  = "S"
  range_key_type = "S"
  read_capacity  = 5
  write_capacity = 5

  additional_attributes = [
    {
      name = "Risk"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      index_name      = "RiskIndex"
      hash_key        = "Risk"
      projection_type = "ALL"
      read_capacity   = 1
      write_capacity  = 1
    }
  ]
}


# lambda functions

# generate csv  

module "generate_csv_function" {
  source          = "../modules/lambda_function"
  filename        = "../modules/lambda_function/code/generatecsv.zip"
  source_file     = "../modules/lambda_function/code/generatecsv.py"
  output_path     = "../modules/lambda_function/code/generatecsv.zip"
  handler_name    = "generatecsv.lambda_handler"
  function_name   = "generate_csv_function"
  lambda_role_arn = module.generate_csv_role.role_arn
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb_table.dynamodb_table_name
    CSV_BUCKET     = "sdfnkefewrekmwkbucket" # placeholder csv bucket
  }
}

module "generate_csv_role" {
  source              = "../modules/iam_role"
  role_name           = "generate_csv_role"
  assume_role_service = "lambda"
  policy_blocks = [
    {
      sid       = "DynamoDB"
      effect    = "Allow"
      actions   = ["dynamodb:Query", "dynamodb:GetItem"]
      resources = ["${module.dynamodb_table.dynamodb_table_arn}", "${module.dynamodb_table.dynamodb_table_arn}/index/RiskIndex"]
    },
    {
      sid       = "s3Access"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["arn:aws:s3:::sdfnkefewrekmwkbucket"] # placeholder csv bucket 
    },
    {
      sid       = "Cloudwatch Logs"
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup"]
      resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    },
    {
      sid       = "Cloudwatch Logs"
      effect    = "Allow"
      actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["*"]
    }
  ]

}

# Get Risks Function

module "get_risks_function" {
  source          = "../modules/lambda_function"
  filename        = "../modules/lambda_function/code/getriskfunction.zip"
  source_file     = "../modules/lambda_function/code/getriskfunction.py"
  output_path     = "../modules/lambda_function/code/getriskfunction.zip"
  handler_name    = "getriskfunction.lambda_handler"
  function_name   = "get_risks_function"
  lambda_role_arn = module.get_risks_role.role_arn
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb_table.dynamodb_table_name
  }
}

module "get_risks_role" {
  source              = "../modules/iam_role"
  role_name           = "get_risks_role"
  assume_role_service = "lambda"
  policy_blocks = [
    {
      sid       = "Well Architected"
      effect    = "Allow"
      actions   = ["wellarchitected:GetLensReviewReport", "wellarchitected:GetWorkload", "wellarchitected:ListAnswers"]
      resources = ["*"]
    },
    {
      sid       = "DynamoDB"
      effect    = "Allow"
      actions   = ["dynamodb:PutItem"]
      resources = ["${module.dynamodb_table.dynamodb_table_arn}"]
    },
    {
      sid       = "Cloudwatch Logs"
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup"]
      resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    },
    {
      sid       = "Cloudwatch Logs"
      effect    = "Allow"
      actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["*"]
    }
  ]

}