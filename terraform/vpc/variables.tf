variable "region" {
  description = "The AWS VPC region to deploy into"
  default     = "us-east-1"
  
}
### VPC Variables
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

### Public Subnet Variables
variable "public_subnet_1_cidr" {
  description = "The CIDR block for the public subnet 1"
  
}
variable "public_subnet_2_cidr" {
  description = "The CIDR block for the public subnet 2"
  
}
variable "public_subnet_3_cidr" {
  description = "The CIDR block for the public subnet 3"
  
}


### Private Subnet Variables
variable "private_subnet_1_cidr" {
  description = "The CIDR block for the private subnet 1"
  
}
variable "private_subnet_2_cidr" {
  description = "The CIDR block for the private subnet 2"
  
}
variable "private_subnet_3_cidr" {
  description = "The CIDR block for the private subnet 3"

  
}
