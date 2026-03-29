
# existing vpc 

data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

# existing subnet 
data "aws_subnet" "public_subnet" {
  id = var.public_subnet_id
}

data "aws_subnet" "private_subnet" {
  id = var.private_subnet_id
}


# IAM ROLE


data "aws_iam_role" "ec2_role" {
  name = "capstone-role"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "capstone-instance-profile"
  role = data.aws_iam_role.ec2_role.name
}


# EXTERNAL ALB SG


resource "aws_security_group" "external_alb_sg" {
  name_prefix = "external-alb-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  security_groups = [aws_security_group.web_sg.id]
}

  tags = {
    Name = "external-alb-sg"
  }
}


# WEB TIER SG

resource "aws_security_group" "web_sg" {
  name_prefix = "web-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # From External ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]
  }

  # HTTPS to Internet

  ingress {
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  security_groups = [aws_security_group.external_alb_sg.id]
}


  # To Internal LB
  egress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }

  egress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = {
    Name = "web-tier-sg"
  }
}


# INTERNAL ALB SG

resource "aws_security_group" "internal_alb_sg" {
  name_prefix = "internal-alb-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # From Web Tier
  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # To App Tier
  egress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  tags = {
    Name = "internal-alb-sg"
  }
}


# APP TIER SG


resource "aws_security_group" "app_sg" {
  name_prefix = "app-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # From Internal LB
  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }

  # To DB
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id]
  }

  tags = {
    Name = "app-tier-sg"
  }
}


# DATABASE SG

resource "aws_security_group" "db_sg" {
  name_prefix = "db-tier-sg-"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  tags = {
    Name = "db-tier-sg"
  }
}

# do not  allow any outbound in database for security reason 


# WEB INSTANCE

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


# APP INSTANCE


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