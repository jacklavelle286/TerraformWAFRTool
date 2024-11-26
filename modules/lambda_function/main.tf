resource "aws_lambda_function" "this" {
  filename = var.filename
  handler = var.handler_name
  function_name = var.function_name
  role = var.lambda_role_arn
  memory_size = var.memory_size
  runtime = var.runtime
  timeout = var.timeout
  layers           = length(var.lambda_layers) > 0 ? var.lambda_layers : null
  environment {
    variables = { for key, value in var.environment_variables : key => value }
      
    }

}

data "archive_file" "lambda" {
  type = "zip"
  source_file = var.source_file
  output_path = var.output_path
  
}

