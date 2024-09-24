#Schedule the lambda to run every time something happens with the S3 extraction bucket

resource "aws_lambda_permission" "allow_s3_extraction" {
  statement_id =  "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transformation_lambda.function_name
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.extraction_bucket.arn
}

resource "aws_s3_bucket_notification" "aws_s3_extraction_bucket_notification" {
  bucket = aws_s3_bucket.extraction_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transformation_lambda.arn
    events = ["s3:ObjectCreated:*"]
  }

  depends_on = [ aws_lambda_permission.allow_s3_extraction]
}

