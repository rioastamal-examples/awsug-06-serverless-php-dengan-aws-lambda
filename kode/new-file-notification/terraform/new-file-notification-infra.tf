provider "aws" {
  version = "~> 2.61"
}

variable "default_tags" {
  type = map
  default = {
    Env = "Demo"
    App = "New File Notification"
    FromTerraform = "true"
    Talk = "AWS UG Surabaya 06"
  }
}

variable "bref_layer_arn" {
  type = string
  default = "arn:aws:lambda:ap-southeast-1:209497400698:layer:php-73:25"
}

resource "aws_iam_role" "s3_new_file" {
  name = "IAMLambdaNewFileNotificationDemo"
  tags = var.default_tags
  description = "Allows Lambda functions to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_new_file_policy" {
  role = aws_iam_role.s3_new_file.id
  # AWS Managed
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create S3 bucket to monitor
resource "aws_s3_bucket" "s3_new_file" {
  bucket = "awsug06-sub-demo"
  tags = var.default_tags
  force_destroy = true
}

# Lambda function using local file as source
resource "aws_lambda_function" "s3_new_file" {
  function_name = "s3-event-notifier"
  handler       = "index.php"
  role          = aws_iam_role.s3_new_file.arn
  memory_size   = 512
  runtime       = "provided"
  tags          = var.default_tags
  timeout       = 5
  layers        = [var.bref_layer_arn]
  environment {
    variables = {
      AWSUG_EMAIL = "awsug-sub-06@aws.com"
      AWSUG_SMTP_HOST = aws_instance.mailhog_demo.public_ip
      AWSUG_SMTP_PORT = 1025
      AWSUG_SMTP_USER = null
      AWSUG_SMTP_PASSWD = null
    }
  }

  filename = "${path.module}/../build/function.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/function.zip")
}

# By default other AWS resource can not call Lambda function
# It needs to be granted manually by giving lambda:InvokeFunction permission
resource "aws_lambda_permission" "s3_new_file" {
  statement_id  = "AllowS3ToInvokeLambdaOnNewFile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_new_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_new_file.arn
}

# Event notification for Lambda
resource "aws_s3_bucket_notification" "s3_new_file" {
  bucket = aws_s3_bucket.s3_new_file.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_new_file.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_function.s3_new_file,
    aws_lambda_permission.s3_new_file
  ]
}