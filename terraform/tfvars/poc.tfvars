environment      = "poc"
primary_location = "uksouth"
locations        = ["uksouth"]
subscription_id  = "ecc74148-1a84-4ec7-99bb-d26aba7f9c0d"

address_spaces = {
  "uksouth" = "10.0.0.0/16"
}

subnets = {
  "uksouth" = {
    "endpoints" = "10.0.1.0/24",
    "app_01"    = "10.0.2.0/24",
    "app_02"    = "10.0.3.0/24"
  }
}

tags = {
  Environment = "poc",
  Workload    = "proof-of-concept",
  DeployedBy  = "GitHub-Terraform",
}
