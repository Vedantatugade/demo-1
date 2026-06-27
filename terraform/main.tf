# use existing vpc
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

#public subnet for web tier
data "aws_subnet" "public_subnet" {
  id = var.public_subnet_id
}

#private subnet for app tier
data "aws_subnet" "private_subnet" {
  id = var.private_subnet_id
}

#  Use existing IAM ROLE
data "aws_iam_role" "ec2_role" {
  name = "new-final"
}

# Use existing iam role
data "aws_iam_instance_profile" "ec2_profile" {
  name = "new-final-profile"
}

#web tier sg
data "aws_security_group" "web_sg" {
  id = var.web_sg_id
}

#app tier sg
data "aws_security_group" "app_sg" {
  id = var.app_sg_id
}


# WEB EC2

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [data.aws_security_group.web_sg.id]

  associate_public_ip_address = true

  # Attach existing instance profile
  iam_instance_profile = data.aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "web-tier"
  }
}


# APP EC2

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [data.aws_security_group.app_sg.id]

  associate_public_ip_address = false

  #  Attach existing instance profile
  iam_instance_profile = data.aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app-tier"
  }
}
