provider "aws" {
  region = "ap-south-1"
}

#################################
# VARIABLES
#################################
variable "my_ip" {
  description = "Your public IP for SSH"
  default     = "YOUR_IP/32"
}

#################################
# EXISTING VPC & SUBNETS
#################################
data "aws_vpc" "existing_vpc" {
  id = "vpc-0133db51cca7dc45f"
}

data "aws_subnet" "public_subnet" {
  id = "subnet-0a6da8a03ca606e04"
}

data "aws_subnet" "private_subnet" {
  id = "subnet-04c24f8796b39cd42"
}

#################################
# SECURITY GROUP - WEB
#################################
resource "aws_security_group" "web_sg" {
  name   = "web-tier-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  # HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from your IP only
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
    Name = "web-tier-sg"
  }
}

#################################
# SECURITY GROUP - APP
#################################
resource "aws_security_group" "app_sg" {
  name   = "app-tier-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  # Allow app traffic ONLY from web tier
  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # SSH ONLY from web tier (secure)
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
    Name = "app-tier-sg"
  }
}

#################################
# EC2 - WEB (PUBLIC)
#################################
resource "aws_instance" "web" {
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t3.micro"
  key_name      = "my-tf-key"

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
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t3.micro"
  key_name      = "my-tf-key"

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