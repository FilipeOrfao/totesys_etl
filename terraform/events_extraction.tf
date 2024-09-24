#Schedule the eventsbridge rate of lambda execution of the extraction lambda

resource "aws_cloudwatch_event_rule" "extraction_lambda_scheduler" {
 name = "${var.lambda_extraction}-eventsbridge-ruler-sorceress"
 description = "Triggers the ${var.lambda_extraction} function every 10 minutes"
 schedule_expression = "rate(10 minutes)"
}

#Link the two resources together
resource "aws_cloudwatch_event_target" "extraction_lambda_handler_to_scheduler" {
  rule      = aws_cloudwatch_event_rule.extraction_lambda_scheduler.name
  target_id = "${var.lambda_extraction}"
  arn       = aws_lambda_function.extraction_lambda.arn
}

#Allow the eventsbridge to invoke the lambda

resource "aws_lambda_permission" "allow_eventbridge_extraction" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.extraction_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.extraction_lambda_scheduler.arn
  source_account = data.aws_caller_identity.current.account_id
}