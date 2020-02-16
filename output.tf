output "sns_topic_arn" {
  value       = "${aws_sns_topic.sns_billing_alert_topic.*.arn}"
  description = "ARN of the SNS topic where billing monitor fucntion will push message."
}
