########################################
# VPC & SUBNET VARIABLES
########################################

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the existing public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the existing private subnet"
  type        = string
}


variable "web_sg_id" {
  description = "Security Group ID for Web Tier (existing)"
  type        = string
}

variable "app_sg_id" {
  description = "Security Group ID for App Tier (existing)"
  type        = string
}

########################################
# EC2 INSTANCE VARIABLES
########################################

variable "ami_id" {
  description = "AMI ID for EC2 instances (must match region)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 Key Pair"
  type        = string
}

