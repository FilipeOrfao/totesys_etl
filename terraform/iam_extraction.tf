# Extraction Lambda Role
resource "aws_iam_role" "extraction_lambda_role" {
  name               = "lambda_${var.lambda_extraction}_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_extract_role_policy.json
}

# Policy document for Extraction Lambda
data "aws_iam_policy_document" "lambda_extract_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Extraction lambda s3 policy document
data "aws_iam_policy_document" "s3_extraction_document" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${var.extraction_bucket}/*"]
  }

  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.lambda_layer_bucket.bucket}/*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/extraction_lambda:*"]
  }
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:eu-west-2:851725604816:secret:totesysinfo-dnApIm"]
  }
  statement {
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = ["arn:aws:ssm:eu-west-2:851725604816:parameter/latest_date"]
  }


  # Allow SNS:Publish
  statement {
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.extraction_lambda_errors.arn]
  }
}

# IAM policy for s3 and cloudwatch
resource "aws_iam_policy" "s3_extraction_policy" {
  name   = "${var.lambda_extraction}_s3_cw_logs_policy"
  policy = data.aws_iam_policy_document.s3_extraction_document.json
}

# Attach the policy to the extraction lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment_extraction" {
  role       = aws_iam_role.extraction_lambda_role.name
  policy_arn = aws_iam_policy.s3_extraction_policy.arn
}

# Extraction Cloudwatch document
data "aws_iam_policy_document" "cw_extract_document" {
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
resource "aws_iam_policy" "extraction_cw_policy" {
  name   = "extraction_cw_policy"
  policy = data.aws_iam_policy_document.cw_extract_document.json
}

resource "aws_iam_role_policy_attachment" "extract_lambda_cw_policy_attachment" {
  role       = aws_iam_role.extraction_lambda_role.name
  policy_arn = aws_iam_policy.extraction_cw_policy.arn
}