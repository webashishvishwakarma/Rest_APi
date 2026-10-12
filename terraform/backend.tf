terraform {
  backend "s3" {
    bucket       = "tfstate-629843008728-ap-south-1"
    key          = "rest-api/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
