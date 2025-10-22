variable "ami_id" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "db_schema" {}
variable "db_engine" {}
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

provider "aws" {
  region = "us-east-1"
}
