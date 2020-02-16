module "billing_monitor_test" {
  source = "../"

  threshold = 1
  custom_tags = {
    Company = "ACME Inc"
    Project = "Billing monitor"
  }
}

