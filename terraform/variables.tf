variable "my_ip" {
  description = "public IP for SSH"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
  type        = string
}

variable "internal_alb_sg_id" {
  description = "internal lb sg"
  type = string
}

variable "external_alb_sg_id" {
  description = "internal lb sg"
  type = string
}

variable "rdb_sg_id" {
  description = "Database Security Group ID (manually created)"
  type        = string
}





