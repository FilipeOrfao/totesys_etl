# 
# Zip the test transform lambda function
data "archive_file" "transformation_lambda_zip" {
    type = "zip"
    source_dir = "${path.module}/../src/lambda_transformation_folder/"
    output_path = "${path.module}/../terraform/zips/lambda_transformation_code.zip"
}
# 
# Add the transformation code to the bucket
resource "aws_s3_object" "transformation_lambda_zip" {
    bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    key = "lambda/lambda_transformation_code.zip"
    source = data.archive_file.transformation_lambda_zip.output_path
    source_hash = data.archive_file.transformation_lambda_zip.output_base64sha256
}

# Create transformation lambda function and link to layers
resource "aws_lambda_function" "transformation_lambda" {
    function_name = "lambda_transformation"
    role = aws_iam_role.transformation_lambda_role.arn
    handler = "lambda_transformation.lambda_handler"
    runtime = "python3.11"
    s3_bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    s3_key = aws_s3_object.transformation_lambda_zip.key
    timeout = 60
    layers = [aws_lambda_layer_version.lambda_layer.arn,aws_lambda_layer_version.wrangler_layer.arn, "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12"]
    source_code_hash = data.archive_file.transformation_lambda_zip.output_base64sha256
}