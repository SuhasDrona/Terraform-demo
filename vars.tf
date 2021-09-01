variable "AWS_REGION" {
  default = "us-west-1"
}


variable "cidr_block_public" {
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "cidr_block_private" {
    type = list(string)
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zone" {
    type = list(string)
    default = ["us-west-1a", "us-west-1b", "us-west-1c"]
}
