#this is the metric filter for the transformation lambda log 

#create Cloudwatch metric filter

resource "aws_cloudwatch_log_metric_filter" "transformation_lambda_filter"{
name = "${var.lambda_transformation}-ErrorFilter"
pattern = "ERROR"
log_group_name = aws_cloudwatch_log_group.transformation_lambda_log_group.name 

metric_transformation {
name = "${var.lambda_transformation}-ErrorFilter"
namespace = "/aws/lambda/${var.lambda_transformation}"
value = "1"
}
}

#create the log group for the extraction lambda

resource "aws_cloudwatch_log_group" "transformation_lambda_log_group" {
name = "/aws/lambda/${var.lambda_transformation}"
}

resource "aws_cloudwatch_metric_alarm" "transformation_lambda_alert_alarm"{
alarm_name = "${var.lambda_transformation}-Error Alarm"
comparison_operator = "GreaterThanOrEqualToThreshold"
metric_name = aws_cloudwatch_log_metric_filter.transformation_lambda_filter.metric_transformation[0].name
namespace = aws_cloudwatch_log_metric_filter.transformation_lambda_filter.metric_transformation[0].namespace
period = "60"
statistic = "Sum"
threshold = "1"
# this is the email messege
alarm_description = "Error threshold breached for ${var.lambda_transformation}"
#links the email the sns.tf
alarm_actions =  [aws_sns_topic.transformation_lambda_errors.arn]
datapoints_to_alarm = "1"
evaluation_periods = "1"
treat_missing_data = "missing"
}