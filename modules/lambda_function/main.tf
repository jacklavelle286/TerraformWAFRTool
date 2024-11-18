resource "aws_lambda_function" "this" {
  filename = var.filename
  handler = var.handler_name
  function_name = var.function_name
  role = var.lambda_role_arn
  runtime = var.runtime
  environment {
    variables = { for key, value in var.environment_variables : key => value }
      
    }

}

data "archive_file" "lambda" {
  type = "zip"
  source_file = var.source_file
  output_path = var.output_path
  
}
