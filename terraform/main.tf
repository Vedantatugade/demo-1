# Existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-0133db51cca7dc45f"
}

# Public Subnet (Web Tier)
data "aws_subnet" "public_subnet" {
  id = "subnet-0a6da8a03ca606e04"
}

# Private Subnet (App Tier)
data "aws_subnet" "private_subnet" {
  id = "subnet-04c24f8796b39cd42"
}

#################################
# WEB TIER SG
#################################
resource "aws_security_group" "web_sg" {
  name   = "web-tier-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  # HTTP from Internet (FIXED CIDR)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/22"]   # ✅ fixed
  }

  # HTTP from ALB
  ingress {
    description     = "Allow HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["sg-0f6ffd57fdfa5253d"]
  }

  ingress {
  description = "SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["223.228.60.89/32"]
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
# APP TIER SG
#################################
resource "aws_security_group" "app_sg" {
  name   = "app-tier-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    description     = "Allow traffic from Web Tier"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  
  ingress {
  description = "SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["223.228.60.89/32"]
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
# WEB TIER INSTANCE
#################################
resource "aws_instance" "web" {
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t3.micro"
  

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = "capstone-role"

  associate_public_ip_address = true

  tags = {
    Name = "web-tier"
  }
}

#################################
# APP TIER INSTANCE
#################################
resource "aws_instance" "app" {
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t3.micro"
  

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

   iam_instance_profile = "capstone-role"

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

output "ec2_ip" {
  value = aws_instance.web.public_ip
}