# General variables

variable "environment" {
  description = "Environment for wich this module will be created. E.g. Development"
  type        = string
  default     = "Development"
}

variable "custom_tags" {
  description = "Optional tags to be applied on top of the base tags on all resources"
  type        = map(string)
  default     = {}
}

# Lambda monitor billing variables
variable "threshold" {
  description = "Threshold for billing monitor. If the estimated billing is above this threshold the lambda function will push a message to SNS topic"
  type        = string
}

variable "currency" {
  description = "Currency in wich billing is"
  type        = string
  default     = "USD"
}

variable "aws_sns_topic_arn" {
  description = "ARN of SNS topic where to push notifications. If is not set terraform will be create a SNS topic."
  type        = string
  default     = ""
}

variable "log_retention" {
  description = "Specifies the number of days you want to retain log events in the specified log group."
  type        = number
  default     = 14
}

