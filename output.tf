# output "Server_public_ip" {
#     value = [aws_subnet.main-public-subnet.id]
# }

output "instance_public_ip_addr" {
  value = aws_instance.myec2.public_ip
}