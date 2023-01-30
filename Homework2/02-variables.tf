# variable "local_host_ip" {
#   description = "the host of the admin- external ip"
#   type = string
#   default = "46.121.0.238/32"
# }

#TO DO cidr_block = “10.0.${(count.index + 1)}.0/24”

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "aws_region" {
   default = "us-west-2"
}

variable "aws_ami" {
    description = "aws linux"
   default = "ami-06e85d4c3149db26a"
}

variable "instance_type" {
   description = "Type of AWS EC2 instance."
   default     = "t3.micro"
}

# #To DO
# variable "public_key_path" {
#   description = "Enter the path to the SSH Public Key to add to AWS."
#   default     = "mnt/c/Users/hadar/.ssh/hadar-key.pem"
# }

variable "key_name" {
   description = "AWS key name"
   default     = "cloud9-key"
}

variable "instance_count" {
   default = 2
}

