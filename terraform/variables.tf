variable "project" {
  type    = string
  default = "rest-api"
}

variable "my_ip" {
  description = "Your public IP in CIDR form, e.g. 1.2.3.4/32. Only this IP can SSH."
  type        = string
}

variable "availability_zone" {
  type    = string
  default = "ap-south-1a"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/devops-key.pub"
}
