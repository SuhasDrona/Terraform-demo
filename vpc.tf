# Internet VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "main"
  }
}

# Subnets
resource "aws_subnet" "main-public-subnet" {

  count = length(var.cidr_block_public)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_block_public[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone[count.index]

  tags = {
    Name = "Main public ${count.index}"
  }
}

resource "aws_subnet" "main-private-subnet" {

  count = length(var.cidr_block_private)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_block_private[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone[count.index]

  tags = {
    Name = "Main private ${count.index}"
  }
}



resource "aws_instance" "myec2" {
  ami                    = "ami-04b6c97b14c54de18"
  instance_type          = "t2.micro"
  key_name               = "terraform-remote-exec-test"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  depends_on = [aws_subnet.main-public-subnet]
  subnet_id              = aws_subnet.main-public-subnet[0].id
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install nginx1.12",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./terraform-remote-exec-test.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH into VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# s3 bucket for storing state file
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "terraform-tfstate-demo-remote-backend"
#   versioning {
#     enabled = true
#   }
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-lock-tfstate-demo"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }
