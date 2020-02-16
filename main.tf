resource "aws_sns_topic" "sns_billing_alert_topic" {
  count = var.aws_sns_topic_arn == "" ? 1 : 0
  name  = "billing-alarm-notification-${lower(var.currency)}-${var.environment}"

  tags = merge(map("DeployedBy", "terraform"), var.custom_tags)
}

resource "aws_lambda_function" "billing_monitor" {
  filename      = "${path.module}/billing_monitor.zip"
  function_name = "billing_monitor"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "billing_monitor.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${path.module}/billing_monitor.zip")

  runtime = "python3.8"

  environment {
    variables = {
      Topic_ARN = "${var.aws_sns_topic_arn == "" ? "${aws_sns_topic.sns_billing_alert_topic.0.arn}" : "${var.aws_sns_topic_arn}"}"
      THRESHOLD = var.threshold
      Currency  = var.currency
    }
  }
  tags = merge(map("DeployedBy", "terraform"), var.custom_tags)
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "billing_monitor_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge(map("DeployedBy", "terraform"), var.custom_tags)

}

resource "aws_cloudwatch_log_group" "billing_alarm" {
  name              = "/aws/lambda/${aws_lambda_function.billing_monitor.function_name}"
  retention_in_days = var.log_retention

  tags = merge(map("DeployedBy", "terraform"), var.custom_tags)

}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "billing_policy" {
  name        = "lambda_billing_monitor"
  path        = "/"
  description = "IAM policy for get metrc statics, push SNS message and get account ID from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "${var.aws_sns_topic_arn == "" ? "${aws_sns_topic.sns_billing_alert_topic.0.arn}" : "${var.aws_sns_topic_arn}"}"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "billing_monitor" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.billing_policy.arn
}

resource "aws_cloudwatch_event_rule" "every_day" {
  name        = "Invoke_billing_monitor"
  description = "Invoke billing monitor once a day"

  schedule_expression = "cron(15 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "billing_monitor" {
  rule = aws_cloudwatch_event_rule.every_day.name
  arn  = aws_lambda_function.billing_monitor.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_billing_monitor_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.billing_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day.arn
}
