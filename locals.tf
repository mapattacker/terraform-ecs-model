locals {
  tags = {
    project     = var.project
    terraform   = "true"
    division    = "aipo"
    team        = "devsecops"
    environment = var.env
  }
}