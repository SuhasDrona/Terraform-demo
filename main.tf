provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Internet VPC
resource "aws_vpc" "vpc-test" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "vpc-test"
  }
}

# Subnets
resource "aws_subnet" "public-subnet" {

  count = length(var.cidr_block_public)

  vpc_id                  = aws_vpc.vpc-test.id
  cidr_block              = var.cidr_block_public[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private-subnet" {

  count = length(var.cidr_block_private)

  vpc_id                  = aws_vpc.vpc-test.id
  cidr_block              = var.cidr_block_private[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gateway-test" {
  vpc_id = aws_vpc.vpc-test.id
  tags = {
    Name = "gateway-test"
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc-test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway-test.id
  }

  tags = {
    Name = "prod-public-route"
  }
}

resource "aws_route_table_association" "public-route-association" {
  subnet_id      = aws_subnet.public-subnet[0].id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "myec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.terraform.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  depends_on             = [aws_subnet.public-subnet]
  subnet_id              = aws_subnet.public-subnet[0].id
  provisioner "remote-exec" {
    inline = [
      # "sudo amazon-linux-extras install nginx1.12",
      # "sudo systemctl start nginx"
      "sudo yum update -y",
      "sudo yum install ec2-instance-connect -y"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
      timeout     = "30s"
      agent = true
    }
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH Traffic from everywhere"
  vpc_id      = aws_vpc.vpc-test.id

  ingress {
    description = "Allow traffic from everywhere on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# storing state file in s3
terraform {
  backend "s3" {
    bucket = "terraform-tfstate-demo-remote-backend"
    key    = "terraform.tfstate"
    region = "us-west-1"

    dynamodb_table = "s3-lock-tfstate-demo"
  }
}