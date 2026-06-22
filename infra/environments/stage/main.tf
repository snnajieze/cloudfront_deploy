module "site" {
  source = "../../modules/static_site"

  environment        = "stage"
  project_name       = var.project_name
  enabled            = var.enabled
  log_retention_days = var.log_retention_days
  price_class        = "PriceClass_100"

  tags = {
    Owner = "fsl-devops-challenge"
  }
}
