# aws-terraform-billing-monitor

This module sets up a lambda function that runs every day, makes a forecast of the billing and it is above threshold push notification to SNS topic.

## Usage

```HCL
module "billing_monitor_test" {
  source = "../"

  threshold = 1
  custom_tags = {
    Company = "ACME Inc"
    Project = "Billing monitor"
  }
}
```


## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_sns\_topic\_arn | ARN of SNS topic where to push notifications. If is not set terraform will be create a SNS topic. | `string` | `""` | no |
| currency | Currency in wich billing is | `string` | `"USD"` | no |
| custom\_tags | Optional tags to be applied on top of the base tags on all resources | `map(string)` | `{}` | no |
| environment | Environment for wich this module will be created. E.g. Development | `string` | `"Development"` | no |
| log\_retention | Specifies the number of days you want to retain log events in the specified log group. | `number` | `14` | no |
| threshold | Threshold for billing monitor. If the estimated billing is above this threshold the lambda function will push a message to SNS topic | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| sns\_topic\_arn | ARN of the SNS topic where billing monitor fucntion will push message. |

## SNS topic subscription

email protocol is unsupported. You have to subscribe to the SNS manually.

These are unsupported because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated. This breaks the Terraform model and as a result are not currently supported.

## Authors

Module managed by [Santiago Zurletti](https://github.com/KiddoATOM).

## License

Apache 2 Licensed. See LICENSE for full details.