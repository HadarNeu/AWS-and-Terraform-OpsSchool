# variable "region" {
#   default     = "us-west-1"
#   description = "AWS region"
# }

# variable "local_host_ip" {
#   description = "the host of the admin- external ip"
#   type = string
#   default = "46.121.0.238/32"
# }

# variable "private_subnets" {
#   default = ["10.0.0.0/19", "10.0.32.0/19"]
# }

# variable "public_subnets" {
#   default = ["10.0.64.0/19", "10.0.96.0/19"]
# }

variable "aws_region" {
   default = "us-west-2"
}

variable "aws_ami" {
    description = "aws linux"
   default = "ami-0ceecbb0f30a902a6"
}

variable "instance_type" {
   description = "Type of AWS EC2 instance."
   default     = "t3.micro"
}

#To DO
variable "public_key_path" {
   description = "Enter the path to the SSH Public Key to add to AWS."
   default     = "mnt/c/Users/hadar/.ssh/hadar-key.pem"
}

#To do
variable "key_name" {
   description = "AWS key name"
   default     = "hadar-key"
}

variable "instance_count" {
   default = 2
}