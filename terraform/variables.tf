
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}


variable "web_sg_id" {
  description = "Web security group ID"
  type        = string
}

variable "app_sg_id" {
  description = "App security group ID"
  type        = string
}


variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}
