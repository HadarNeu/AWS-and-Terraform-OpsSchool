#resource "aws_default_vpc" "default" {}

resource "aws_security_group" "allow_ports" {
   name        = "allow_ssh_http"
   description = "Allow inbound SSH traffic and http from any IP"
   # TO DO configure vpc id from data recource
#   vpc_id      = "${module.vpc.vpc_id}"

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

data "template_file" "bootscript" {
  template = "${file("user_data.sh")}"

}
resource "aws_instance" "webserver" {
   availability_zone =  data.aws_availability_zones.available.names[0]
   instance_type          = "${var.instance_type}"
   ami                    = "${var.aws_ami}"
   count                  = "${var.instance_count}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]  
   user_data                   = "${data.template_file.bootscript.rendered}"
  
   tags = {
       Name = "Webserver"
       Owner = "hadarNoy"
       Purpose = "Whiskey Website"
   }
}

data "aws_availability_zones" "available" {
}

resource "aws_ebs_volume" "enc_ebs" {
  count = var.instance_count
  availability_zone =  data.aws_availability_zones.available.names[0]
  size              = 10
  type = "gp2"
  encrypted = true
}

resource "aws_volume_attachment" "ebs_att" {
  count = var.instance_count
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.enc_ebs[count.index].id
  instance_id = aws_instance.webserver[count.index].id
}
