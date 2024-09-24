# Loading Lambda Role
resource "aws_iam_role" "loading_lambda_role" {
  name               = "lambda_${var.lambda_loading}_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_loading_role_policy.json
}

# Policy document for Loading Lambda
data "aws_iam_policy_document" "lambda_loading_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Loading lambda s3 policy document
data "aws_iam_policy_document" "s3_loading_document" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${var.loading_bucket}/*"]
  }

  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.lambda_layer_bucket.bucket}/*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/loading_lambda:*"]
  }
  statement {
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = ["arn:aws:ssm:eu-west-2:851725604816:parameter/latest_date"]
  }


  # Allow SNS:Publish
  statement {
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.loading_lambda_errors.arn]
  }
}

# IAM policy for s3 and cloudwatch
resource "aws_iam_policy" "s3_loading_policy" {
  name   = "${var.lambda_loading}_s3_cw_logs_policy"
  policy = data.aws_iam_policy_document.s3_loading_document.json
}

# Attach the policy to the loading lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment_loading" {
  role       = aws_iam_role.loading_lambda_role.name
  policy_arn = aws_iam_policy.s3_loading_policy.arn
}

# Extraction Cloudwatch document
data "aws_iam_policy_document" "cw_load_document" {
  statement {
    actions = ["logs:CreateLogGroup"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/extraction_lambda:*"
    ]
  }
}

# IAM for cloudwatch logs
resource "aws_iam_policy" "loading_cw_policy" {
  name   = "loading_cw_policy"
  policy = data.aws_iam_policy_document.cw_load_document.json
}

resource "aws_iam_role_policy_attachment" "loading_lambda_cw_policy_attachment" {
  role       = aws_iam_role.loading_lambda_role.name
  policy_arn = aws_iam_policy.loading_cw_policy.arn
}