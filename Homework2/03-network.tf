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
    "Name" = "Public_subnet_${count.index+1}_${data.aws_availability_zones.available.names[count.index]})"
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
    "Name" = "Private_subnet_${count.index+1}_${data.aws_availability_zones.available.names[count.index]})"
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
  depends_on = [aws_vpc.vpc]
  count = 2
  vpc_id = aws_vpc.vpc.id

    route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "private"
  }
}

// one public route table
resource "aws_route_table" "public" {
  depends_on = [aws_vpc.vpc]
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  

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
    command = "echo '${tls_private_key.ec2-key-pair.private_key_pem}' > ~/.ssh/${var.key_name}.pem && sudo chmod 400 ~/.ssh/${var.key_name}.pem"
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

resource "aws_security_group" "alb_sg" {
   name        = "alb_sg"
   vpc_id      = "${aws_vpc.vpc.id}"

   # HTTP access - Traffic from internet
   ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       # Restrict ingress to necessary IPs/ports.
       cidr_blocks = [aws_vpc.vpc.cidr_block]
   }

  # egress {
  #     from_port   = 80
  #     to_port     = 80
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  # }

   tags = {
       Name = "alb_sg"
   }
}

resource "aws_security_group_rule" "egress_alb_http" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.allow_ports.id
}

# resource "aws_security_group_rule" "ingress_ec2_traffic" {
#   type                     = "ingress"
#   from_port                = 8080
#   to_port                  = 8080
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.allow_ports.id
#   source_security_group_id = aws_security_group.alb_sg.id
# }

# resource "aws_security_group_rule" "ingress_ec2_health_check" {
#   type                     = "ingress"
#   from_port                = 8081
#   to_port                  = 8081
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.allow_ports.id
#   source_security_group_id = aws_security_group.alb_sg.id
# }

# resource "aws_security_group_rule" "egress_alb_traffic" {
#   type                     = "egress"
#   from_port                = 8080
#   to_port                  = 8080
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.alb_sg.id
#   source_security_group_id = aws_security_group.allow_ports.id
# }

# resource "aws_security_group_rule" "egress_alb_health_check" {
#   type                     = "egress"
#   from_port                = 8081
#   to_port                  = 8081
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.alb_sg.id
#   source_security_group_id = aws_security_group.allow_ports.id
# }

# Creating Target Group for public access
resource "aws_lb_target_group" "app_tg" {
  name       = "app-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.vpc.id
  slow_start = 0

  load_balancing_algorithm_type = "round_robin"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    port                = 80
    interval            = 30
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Attechement of target group to webservers
resource "aws_lb_target_group_attachment" "app_tg" {
  count = 2

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.webserver[count.index].id
  port             = 80
}

# Creating the actual Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "AppAlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
}

# A listener to recieve incoming traffic
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "lb_id" {
  description = "The ID and ARN of the load balancer we created"
  value       = try(aws_lb.app_alb.dns_name, "")
}