
########################################
# VPC & SUBNET DATA
########################################

data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnet" {
  id = var.public_subnet_id
}

data "aws_subnet" "private_subnet" {
  id = var.private_subnet_id
}

########################################
# IAM ROLE (EXISTING)
########################################

data "aws_iam_role" "ec2_role" {
  name = "new-final"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "new-final-profile"
  role = data.aws_iam_role.ec2_role.name
}

########################################
# EXISTING SECURITY GROUPS
########################################

# Web SG (already created manually)
data "aws_security_group" "web_sg" {
  id = var.web_sg_id
}

# App SG (already created manually)
data "aws_security_group" "app_sg" {
  id = var.app_sg_id
}

########################################
# WEB EC2 INSTANCE
########################################

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [data.aws_security_group.web_sg.id]

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "web-tier"
  }
}

########################################
# APP EC2 INSTANCE
########################################

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [data.aws_security_group.app_sg.id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app-tier"
  }
}
