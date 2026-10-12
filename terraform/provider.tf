provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "rest-api-devops"
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
