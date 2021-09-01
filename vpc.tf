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


# Internet GW
# resource "aws_internet_gateway" "main-gw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main"
#   }
# }

# route tables
# resource "aws_route_table" "main-public" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main-gw.id
#   }

#   tags = {
#     Name = "main-public-1"
#   }
# }

# route associations public
# resource "aws_route_table_association" "main-public-1-a" {
#   subnet_id      = aws_subnet.main-public-1.id
#   route_table_id = aws_route_table.main-public.id
# }

# resource "aws_route_table_association" "main-public-2-a" {
#   subnet_id      = aws_subnet.main-public-2.id
#   route_table_id = aws_route_table.main-public.id
# }

# resource "aws_route_table_association" "main-public-3-a" {
#   subnet_id      = aws_subnet.main-public-3.id
#   route_table_id = aws_route_table.main-public.id
# }



resource "aws_instance" "myec2" {
  ami                    = "ami-04b6c97b14c54de18"
  instance_type          = "t2.micro"
  key_name               = "terraform-remote-exec-test"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = "subnet-09a1aadddd9ab4a59"
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



# "sudo amazon-linux-extras install -y nginx1.12",
 # "sudo systemctl start nginx",