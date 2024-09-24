
# Zip the lambda layer
# data "archive_file" "lambda_layer_zip" {
#     type = "zip"
#     source_dir = "lambda_layer"
#     output_path = "${path.module}/zips/lambda_layer.zip"
# }

# Zip the wrangler lambda layer
# data "archive_file" "wrangler_layer_zip" {
#     type = "zip"
#     source_dir = "lambda_wrangler_layer"
#     output_path = "${path.module}/zips/lambda_wrangler_layer.zip"
# }

# Add the lambda layer to the bucket
resource "aws_s3_object" "lambda_layer_zip" {
    bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    key = "lambda_library/lambda_layer.zip"
    # source = data.archive_file.lambda_layer_zip.output_path
    source = "${path.module}/zips/lambda_layer.zip"
}

# Add the wrangler lambda layer to the bucket
resource "aws_s3_object" "wrangler_layer_zip" {
    bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    key = "lambda_library/wrangler_layer.zip"
    # source = data.archive_file.wrangler_layer_zip.output_path
    source = "${path.module}/zips/lambda_wrangler_layer.zip"
}

# Create lambda layer from zip
resource "aws_lambda_layer_version" "lambda_layer" {
    layer_name = "sorceress_lambda_layer"
    s3_bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    s3_key = aws_s3_object.lambda_layer_zip.key
    compatible_runtimes  = ["python3.11"]
}

# Create wrangler lambda layer from zip
resource "aws_lambda_layer_version" "wrangler_layer" {
    layer_name = "sorceress_lambda_wrangler_layer"
    s3_bucket = aws_s3_bucket.lambda_layer_bucket.bucket
    s3_key = aws_s3_object.wrangler_layer_zip.key
    compatible_runtimes  = ["python3.11"]
}