variable "ami_id" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

provider "aws" {
  region = "us-east-1"
}
