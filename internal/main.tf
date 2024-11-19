data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# sns topic

module "sns_topic" {
  source = "../modules/sns_topic"
  email_address = var.desination_email_address
}


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
      resources = ["${module.step_functions.state_machine_arn}"] 
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


# generate report 

module "generate_report_function" {
  source          = "../modules/lambda_function"
  filename        = "../modules/lambda_function/code/generatereport.zip"
  source_file     = "../modules/lambda_function/code/generatereport.py"
  output_path     = "../modules/lambda_function/code/generatereport.zip"
  handler_name    = "generatereport.lambda_handler"
  function_name   = "generate_report_function"
  runtime = "python3.11"
  timeout = 300
  lambda_role_arn = module.generate_report_role.role_arn
  lambda_layers       = [
    "${var.python_docx_layer_arn}",
    "${var.matplotlib_layer_arn}"
  ]
  environment_variables = { 
    DYNAMODB_TABLE = module.dynamodb_table.dynamodb_table_name
    TEMPLATE_BUCKET: module.template_bucket.bucket_name
    DESTINATION_BUCKET: module.outputs_bucket.bucket_name
    CSV_BUCKET: module.csv_bucket.bucket_name
  }
}

module "generate_report_role" {
  source              = "../modules/iam_role"
  role_name           = "generate_report_role"
  assume_role_service = "lambda"
  policy_blocks = [
    {
      sid       = "S3get"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.outputs_bucket.bucket_arn}", "${module.csv_bucket.bucket_arn}"] 
    },
    {
      sid       = "s3Put"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.outputs_bucket.bucket_arn}"]  
    },
    {
      sid       = "Well Architected"
      effect    = "Allow"
      actions   = ["wellarchitected:GetAnswer", "wellarchitected:GetMilestone", "wellarchitected:GetWorkload"]
      resources = ["*"]
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
    CSV_BUCKET     = module.csv_bucket.bucket_name 
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
      resources = ["${module.csv_bucket.bucket_arn}"] 
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

# generate presigned url Function

module "presigned_url_function" {
  source          = "../modules/lambda_function"
  filename        = "../modules/lambda_function/code/generatepresigned.zip"
  source_file     = "../modules/lambda_function/code/generatepresigned.py"
  output_path     = "../modules/lambda_function/code/generatepresigned.zip"
  handler_name    = "generatepresigned.lambda_handler"
  function_name   = "presigned_url_function"
  timeout = 300
  lambda_role_arn = module.presigned_url_role.role_arn
  environment_variables = {
    SNS_TOPIC = module.sns_topic.sns_topic_arn 
  }
}

module "presigned_url_role" {
  source              = "../modules/iam_role"
  role_name           = "presigned_url_role"
  assume_role_service = "lambda"
  policy_blocks = [

    {
      sid       = "S3Get"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.outputs_bucket.bucket_arn}"]
    },
    {
      sid       = "SNS"
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = ["${module.sns_topic.sns_topic_arn }"] 
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

# s3 buckets

# csv bucket
module "csv_bucket" {
  source = "../modules/s3"
  bucket_name = "${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-war-csv-bucket"
}


# template bucket

module "template_bucket" {
  source = "../modules/s3"
  bucket_name = "${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-war-template-bucket"
}


# outputs bucket

module "outputs_bucket" {
  source = "../modules/s3"
  bucket_name = "${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-war-outputs-bucket"
}


# state machine


# state machine role 

module "state_machine_role" {
  source              = "../modules/iam_role"
  role_name           = "state_machine_role"
  assume_role_service = "states"
  policy_blocks = [
    {
      sid       = "InvokeLambdas"
      effect    = "Allow"
      actions   = ["lambda:Invoke"]
      resources = ["*"] # 
    },
    {
      sid       = "Cloudwatch Logs"
      effect    = "Allow"
      actions   = ["logs:*"]
      resources = ["${module.step_functions.log_group_arn}"] 
    }
  ]

}

module "step_functions" {
  source              = "../modules/step_functions"
  state_machine_name  = "WellArchitectedReportWorkflow"
  execution_role_arn  = "${module.state_machine_role.role_arn}"

  definition_json = jsonencode({
    Comment = "A workflow to generate a report for a Well-Architected Review and distribute it",
    StartAt = "PutDynamoDBData",
    States = {
      PutDynamoDBData = {
        Type            = "Task",
        Resource        = module.get_risks_function.function_arn,
        TimeoutSeconds  = 120,
        Retry = [
          {
            ErrorEquals   = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
            IntervalSeconds = 2,
            MaxAttempts     = 3,
            BackoffRate     = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "HandlePutDynamoDBFailure"
          }
        ],
        Next = "GenerateCSV"
      },
      GenerateCSV = {
        Type            = "Task",
        Resource        = module.generate_csv_function.function_arn,
        TimeoutSeconds  = 120,
        Retry = [
          {
            ErrorEquals   = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
            IntervalSeconds = 2,
            MaxAttempts     = 3,
            BackoffRate     = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "HandleGenerateCSVFailure"
          }
        ],
        Next = "GenerateFullReport"
      },
      GenerateFullReport = {
        Type            = "Task",
        Resource        = module.generate_report_function.function_arn,
        TimeoutSeconds  = 300,
        Retry = [
          {
            ErrorEquals   = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
            IntervalSeconds = 5,
            MaxAttempts     = 2,
            BackoffRate     = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "HandleFullReportFailure"
          }
        ],
        Next = "GeneratePresignedURL"
      },
      GeneratePresignedURL = {
        Type            = "Task",
        Resource        = module.presigned_url_function.function_arn,
        TimeoutSeconds  = 60,
        Retry = [
          {
            ErrorEquals   = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
            IntervalSeconds = 2,
            MaxAttempts     = 3,
            BackoffRate     = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "HandlePresignedUrlFailure"
          }
        ],
        End = true
      },
      HandlePutDynamoDBFailure = {
        Type   = "Fail",
        Error  = "PutDynamoDBDataFailed",
        Cause  = "Failed to process DynamoDB data"
      },
      HandleGenerateCSVFailure = {
        Type   = "Fail",
        Error  = "GenerateCSVFailed",
        Cause  = "Failed to generate CSV file"
      },
      HandleFullReportFailure = {
        Type   = "Fail",
        Error  = "GenerateFullReportFailed",
        Cause  = "Failed to generate the full report"
      },
      HandlePresignedUrlFailure = {
        Type   = "Fail",
        Error  = "PresignedUrlGenerationFailed",
        Cause  = "Failed to generate presigned URL"
      }
    }
  })
}
