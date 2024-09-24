#Zip the lambda file
data "archive_file" "extraction_lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/../src/lambda_extraction_folder/"
  output_path = "${path.module}/../terraform/zips/lambda_extraction_code.zip"
}

# Add the extraction code to the bucket
resource "aws_s3_object" "extraction_lambda_zip" {
    bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    key = "lambda/lambda_extraction_code.zip"
    source = data.archive_file.extraction_lambda_zip.output_path
    source_hash = data.archive_file.extraction_lambda_zip.output_base64sha256
}

# Create transformation lambda function and link to layers
resource "aws_lambda_function" "extraction_lambda" {
    function_name = "lambda_extraction"
    role = aws_iam_role.extraction_lambda_role.arn
    handler = "extract_lambda.lambda_handler"
    runtime = "python3.11"
    timeout = 60
    s3_bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    s3_key = aws_s3_object.extraction_lambda_zip.key
    # change this to the manual bucket with the lambda layer created outside terraform
    layers = [aws_lambda_layer_version.lambda_layer.arn, "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12"]
    source_code_hash = data.archive_file.extraction_lambda_zip.output_base64sha256
}


