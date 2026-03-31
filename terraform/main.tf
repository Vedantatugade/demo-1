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
# IAM ROLE
########################################

data "aws_iam_role" "ec2_role" {
  name = "capstone-role"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "capstone-instance-profile"
  role = data.aws_iam_role.ec2_role.name
}

########################################
# EXISTING ALB SECURITY GROUPS
########################################

data "aws_security_group" "external_alb_sg" {
  id = var.external_alb_sg_id
}

data "aws_security_group" "internal_alb_sg" {
  id = var.internal_alb_sg_id
}

########################################
# EXISTING DATABASE SECURITY GROUP
########################################

data "aws_security_group" "db_sg" {
  id = var.rdb_sg_id
}

########################################
# WEB SECURITY GROUP
########################################

resource "aws_security_group" "web_sg" {
  name_prefix = "web-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # SSH (only your IP)
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP from External ALB
  ingress {
    description     = "HTTP from external ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.aws_security_group.external_alb_sg.id]
  }

  # HTTPS from External ALB
  ingress {
    description     = "HTTPS from external ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [data.aws_security_group.external_alb_sg.id]
  }

  # Outbound → ONLY Internal ALB
  egress {
    description     = "HTTP to internal ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.aws_security_group.internal_alb_sg.id]
  }

  egress {
    description     = "HTTPS to internal ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [data.aws_security_group.internal_alb_sg.id]
  }

  tags = {
    Name = "web-tier-sg"
  }
}

########################################
# APP SECURITY GROUP
########################################

resource "aws_security_group" "app_sg" {
  name_prefix = "app-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Only from Internal ALB
  ingress {
    description     = "App access from internal ALB"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [data.aws_security_group.internal_alb_sg.id]
  }

  # Outbound → ONLY Database
  egress {
    description     = "MySQL to DB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.db_sg.id]
  }

  tags = {
    Name = "app-tier-sg"
  }
}

########################################
# WEB EC2 INSTANCE
########################################

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

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
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app-tier"
  }
}
