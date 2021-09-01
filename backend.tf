# terraform {
#   backend "s3" {
#     bucket = "terraform-demo-remote-backend"
#     key    = "./terraform.tfstate"
#     region = var.AWS_REGION
#     dynamodb_table = "s3-state-lock"
#   }
# }