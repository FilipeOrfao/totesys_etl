# Make a bucket for the lambda layer

resource "aws_s3_bucket" "lambda_layer_bucket" {
    bucket = "lambda-layer-sorceress"
}

# Make a bucket for the extraction bucket

resource "aws_s3_bucket" "extraction_bucket" {
    bucket = "extraction-bucket-sorceress"
}

# Make a bucket for the transformation bucket

resource "aws_s3_bucket" "transformation_bucket" {
    bucket = "transformation-bucket-sorceress"
}

# Make a bucket final bucket in place of data warehouse

resource "aws_s3_bucket" "warehouse_bucket" {
    bucket = "warehouse-bucket-sorceress"
}