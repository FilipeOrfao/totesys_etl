#This links the SNS topic with the EXTRACTION lambda

resource "aws_sns_topic" "extraction_lambda_errors"{
    name = "SNS_Extraction_Lambda_Error_Email"
}

#This links the EXTRACTION lambda to the SNS subscription
resource "aws_sns_topic_subscription" "extraction_lambda_errors" {
    protocol = "email"
    endpoint = "northcoderssorceress@gmail.com"
    topic_arn = aws_sns_topic.extraction_lambda_errors.arn
}

#This links the SNS topic with the TRANFORMATION lambda

resource "aws_sns_topic" "transformation_lambda_errors"{
    name = "SNS_Transformation_Lambda_Error_Email"
}

#This links the transformation lambda to the SNS subscription

resource "aws_sns_topic_subscription" "transformation_lambda_errors" {
    protocol = "email"
    endpoint = "northcoderssorceress@gmail.com"
    topic_arn = aws_sns_topic.transformation_lambda_errors.arn
}

#This links the SNS topic with the LOADING lambda

resource "aws_sns_topic" "loading_lambda_errors"{
    name = "SNS_Loading_Lambda_Error_Email"
}

#This links the LOADING lambda to the SNS subscription
resource "aws_sns_topic_subscription" "loading_lambda_errors" {
    protocol = "email"
    endpoint = "northcoderssorceress@gmail.com"
    topic_arn = aws_sns_topic.loading_lambda_errors.arn
}