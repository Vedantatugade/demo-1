#vpc and subnet

data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnet" {
  id = var.public_subnet_id
}

data "aws_subnet" "private_subnet" {
  id = var.private_subnet_id
}

#internal load balncer sg

data "aws_security_group" "internal_alb_sg" {
  id = "sg-00dafe10f5caff6e6"
}

# iam role

data "aws_iam_role" "ec2_role" {
  name = "capstone-role"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "capstone-instance-profile"
  role = data.aws_iam_role.ec2_role.name
}

#web-tier sg

resource "aws_security_group" "web_sg" {
  name_prefix = "web-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

# SSH from IP

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

# HTTP public access

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# external load balncer access
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-tier-sg"
  }
}

# app-tier sg

resource "aws_security_group" "app_sg" {
  name_prefix = "app-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

# internal loadbalncer access

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [data.aws_security_group.internal_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-tier-sg"
  }
}

#web-ter instance

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "web-tier"
  }
}

# app-tier instance

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app-tier"
  }
}

