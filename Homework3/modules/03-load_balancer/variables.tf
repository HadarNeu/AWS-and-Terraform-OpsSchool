variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "aws_region" {
   default = "us-west-2"
}

variable "counter" {
   default = "2"
}