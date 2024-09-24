# Transformation Lambda role
resource "aws_iam_role" "transformation_lambda_role" {
  name               = "${var.lambda_transformation}_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_transform_role_policy.json
}

# Policy document for Transformation Lambda

data "aws_iam_policy_document" "lambda_transform_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Policy document for S3 and CloudWatch permissions

data "aws_iam_policy_document" "s3_transformation_document" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${var.transformation_bucket}/*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.extraction_bucket}/*"]
  }


#Permission for lambda_layer bucket
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.lambda_layer_bucket.bucket}/*"]
  }
  statement {
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = ["arn:aws:ssm:eu-west-2:851725604816:parameter/latest_date"]
  }

#Cloudwatch logs
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/transformation_lambda:*"]
  }
}


#IAM policy for s3 and cloudwatch

resource "aws_iam_policy" "s3_transformation_policy" {
    name = "${var.lambda_transformation}_s3_cw_logs_policy"
    policy = data.aws_iam_policy_document.s3_transformation_document.json
}


# Attach the policy to the role

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_transformation" {
  role       = aws_iam_role.transformation_lambda_role.name
  policy_arn = aws_iam_policy.s3_transformation_policy.arn
}


# Trasnformation Cloudwatch document

data "aws_iam_policy_document" "cw_transformation_document" {
  statement {
    actions = ["logs:CreateLogGroup"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/transformation_lambda:*"
    ]
  }
}

# IAM for cloudwatch logs
resource "aws_iam_policy" "transformation_cw_policy" {
  name   = "tranformation_cw_policy"
  policy = data.aws_iam_policy_document.cw_transformation_document.json
}

resource "aws_iam_role_policy_attachment" "extract_transformation_cw_policy_attachment" {
  role       = aws_iam_role.transformation_lambda_role.name
  policy_arn = aws_iam_policy.transformation_cw_policy.arn
}




