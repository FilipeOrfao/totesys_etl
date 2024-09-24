#this is the metric filter for the extraction lambda log 

#create Cloudwatch metric filter

resource "aws_cloudwatch_log_metric_filter" "extraction_lambda_filter"{
name = "${var.lambda_extraction}-ErrorFilter"
pattern = "ERROR"
log_group_name = aws_cloudwatch_log_group.extraction_lambda_log_group.name 

metric_transformation {
name = "${var.lambda_extraction}-ErrorFilter"
namespace = "/aws/lambda/${var.lambda_extraction}"
value = "1"
}
}

#create the log group for the extraction lambda

resource "aws_cloudwatch_log_group" "extraction_lambda_log_group" {
name = "/aws/lambda/${var.lambda_extraction}"
}

resource "aws_cloudwatch_metric_alarm" "extraction_lambda_alert_alarm"{
alarm_name = "${var.lambda_extraction}-Error Alarm"
comparison_operator = "GreaterThanOrEqualToThreshold"
metric_name = aws_cloudwatch_log_metric_filter.extraction_lambda_filter.metric_transformation[0].name
namespace = aws_cloudwatch_log_metric_filter.extraction_lambda_filter.metric_transformation[0].namespace
period = "60"
statistic = "Sum"
threshold = "1"
# this is the email messege
alarm_description = "Error threshold breached for ${var.lambda_extraction}"
#links the email the sns.tf
alarm_actions =  [aws_sns_topic.extraction_lambda_errors.arn]
datapoints_to_alarm = "1"
evaluation_periods = "1"
treat_missing_data = "missing"
}