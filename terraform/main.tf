#################################
# EXISTING VPC & SUBNETS
#################################
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnet" {
  id = var.public_subnet_id
}

data "aws_subnet" "private_subnet" {
  id = var.private_subnet_id
}

#################################
# SECURITY GROUP - WEB
#################################
resource "aws_security_group" "web_sg" {
  name   = "web-tier-sg-1"
  vpc_id = data.aws_vpc.existing_vpc.id

  # HTTP ONLY from ALB SG
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  # SSH from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-tier-sg-1"
  }
}

#################################
# SECURITY GROUP - APP
#################################
resource "aws_security_group" "app_sg" {
  name   = "app-tier-sg-1"
  vpc_id = data.aws_vpc.existing_vpc.id

  # Allow app traffic ONLY from web tier
  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # SSH ONLY from web tier
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-tier-sg-1"
  }
}

#################################
# EC2 - WEB (PUBLIC)
#################################
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "web-tier"
  }
}

#################################
# EC2 - APP (PRIVATE)
#################################
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = false

  tags = {
    Name = "app-tier"
  }
}

#################################
# OUTPUTS
#################################
output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}