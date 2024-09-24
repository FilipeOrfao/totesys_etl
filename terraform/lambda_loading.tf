# 
# Zip the test loading lambda function
data "archive_file" "loading_lambda_zip" {
    type = "zip"
    source_dir = "${path.module}/../src/lambda_loading_folder/"
    output_path = "${path.module}/../terraform/zips/lambda_loading_code.zip"
}
# 
# Add the loading code to the bucket
resource "aws_s3_object" "loading_lambda_zip" {
    bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    key = "lambda/lambda_loading_code.zip"
    source = data.archive_file.loading_lambda_zip.output_path
    source_hash = data.archive_file.loading_lambda_zip.output_base64sha256
}

# Create loading lambda function and link to layers
resource "aws_lambda_function" "loading_lambda" {
    function_name = "lambda_loading"
    role = aws_iam_role.loading_lambda_role.arn
    handler = "lambda_loading.lambda_handler"
    runtime = "python3.11"
    s3_bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    s3_key = aws_s3_object.loading_lambda_zip.key
    timeout = 60
    layers = [aws_lambda_layer_version.lambda_layer.arn,aws_lambda_layer_version.wrangler_layer.arn, "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12"]
    source_code_hash = data.archive_file.loading_lambda_zip.output_base64sha256
}