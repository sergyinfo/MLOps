provider "aws" {
  region = "eu-central-1" # Змініть на свій регіон
}

# --- IAM Roles for Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "mlops_lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Functions ---
resource "aws_lambda_function" "validate" {
  filename      = "lambda/validate.zip"
  function_name = "mlops_validate_data"
  role          = aws_iam_role.lambda_role.arn
  handler       = "validate.lambda_handler"
  runtime       = "python3.11"
}

resource "aws_lambda_function" "log_metrics" {
  filename      = "lambda/log_metrics.zip"
  function_name = "mlops_log_metrics"
  role          = aws_iam_role.lambda_role.arn
  handler       = "log_metrics.lambda_handler"
  runtime       = "python3.11"
}

# --- IAM Role for Step Function ---
resource "aws_iam_role" "sfn_role" {
  name = "mlops_step_function_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_lambda_policy" {
  name = "mlops_sfn_lambda_invoke"
  role = aws_iam_role.sfn_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "lambda:InvokeFunction"
      Effect   = "Allow"
      Resource = [
        aws_lambda_function.validate.arn,
        aws_lambda_function.log_metrics.arn
      ]
    }]
  })
}

# --- Step Function (State Machine) ---
resource "aws_sfn_state_machine" "ml_pipeline" {
  name     = "mlops-training-pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "LogMetrics"
      }
      LogMetrics = {
        Type     = "Task"
        Resource = aws_lambda_function.log_metrics.arn
        End      = true
      }
    }
  })
}

output "step_function_arn" {
  value = aws_sfn_state_machine.ml_pipeline.arn
}