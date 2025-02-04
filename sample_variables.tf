variable "aws_region" {
  type    = string
  default = [YOUR_AWS_REGION]
}

variable "db_name" {
  type    = string
  default = "hstc"
}

variable "db_username" {
  type    = string
  default = [YOUR_DB_USERNAME]
}

variable "db_password" {
  type    = string
  default = [YOUR_DB_PASSWORD]
}

variable "db_port" {
  type = number
  default = 3306
}

variable "third_party_file" {
  type    = string
  default = "./build/layers/third_party.zip"
}

variable "utils_file" {
  type    = string
  default = "./build/layers/common_code.zip"
}

variable "aws_vpc" {
  type = string
  default = [YOUR_VPC_ID] # fount in VPC -> Your VPCs
}

variable "subnet_group" {
  type = string
  default = [YOUR_SUBNET_GROUP] # fount in RDS -> Subnet Groups
}

variable "security_group_id" {
  type = string
  default = [YOUR_SECURITY_GROUP_ID] # fount in VPC -> Security Groups (you can use the default one)
}
