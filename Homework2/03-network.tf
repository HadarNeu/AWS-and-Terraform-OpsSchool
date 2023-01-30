// getting the data recource of available AZ's
data "aws_availability_zones" "available" {
}

// creating the vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc"
  }
}


// creating igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

// creating two public subnets on two AZ's
resource "aws_subnet" "public" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    "Name" = "Private_subnet_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
  }
}

// creating twp private subnets on two AZ's
resource "aws_subnet" "private" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    "Name" = "Private_subnet_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
  }
}

//making 2 elastic IP addresses in case of NAT failure
resource "aws_eip" "nat" {
  count = 2
  vpc = true

  tags = {
    Name = "nat"
  }
}

//making 2 NAT adderses in case of failure- deploying on public subnet.
resource "aws_nat_gateway" "nat" {
  count = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

// making two private route tables for two NAT addresses
resource "aws_route_table" "private" {
  count = 2
  vpc_id = aws_vpc.vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat[count.index].id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "private"
  }
}

// one public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "public"
  }
}

// associating the subnets with the route tables
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


//generating a key pairv
resource "tls_private_key" "ec2-key-pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
  
resource "aws_key_pair" "key_pair" {
  # Create public "hadar-key" on EC2 instance!!
  key_name   = var.key_name      
  public_key = tls_private_key.ec2-key-pair.public_key_openssh
  
  # Create private "hadar-key.pem" on my computer!!
  provisioner "local-exec" { 
    command = "sudo echo '${tls_private_key.ec2-key-pair.private_key_pem}' > ~/.ssh/${var.key_name}.pem && sudo chmod 400 ~/.ssh/${var.key_name}.pem"
  }
}


resource "aws_security_group" "allow_ports" {
   name        = "allow_ssh_http"
   description = "Allow inbound SSH traffic and http from any IP"
   # TO DO configure vpc id from data recource
   vpc_id      = "${aws_vpc.vpc.id}"

   #ssh access
   ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = ["0.0.0.0/0"]
   }

   # HTTP access
   ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
   }
  
   tags = {
       Name = "Allow SSH and HTTP"
   }
}

resource "aws_security_group" "db_sg" {
   name        = "db_sg"
   description = "Allow inbound SSH traffic from anywhere and http from the vpc"
   vpc_id      = "${aws_vpc.vpc.id}"

   #ssh access
   ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = [aws_vpc.vpc.cidr_block]
   }

   # HTTP access
   ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = [aws_vpc.vpc.cidr_block]
   }

   egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
   }
  
   tags = {
       Name = "db_sg"
   }
}