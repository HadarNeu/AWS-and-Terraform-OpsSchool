# data "template_file" "bootscript" {
#   template = "${file("user_data.sh")}"

# }

resource "aws_instance" "webserver" {
   count = "${var.instance_count}"
   subnet_id = "${aws_subnet.private[count.index].id}"
   instance_type          = "${var.instance_type}"
   ami                    = "${var.aws_ami}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]  
   #user_data                   = "${data.template_file.bootscript.rendered}"
   user_data = "${file("user_data.sh")}"
  
   tags = {
       Name = "'Webserver'-EC2-${count.index+1}"
       Owner = "hadarNoy"
       Purpose = "Whiskey Website"
   }
}

resource "aws_instance" "cb-server" {
   count = "${var.instance_count}"
   subnet_id = "${aws_subnet.private[count.index].id}"
   instance_type          = "${var.instance_type}"
   ami                    = "${var.aws_ami}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]  
  
   tags = {
       Name = "'DBserver'-EC2-${count.index+1}"
       Owner = "hadarNoy"
       Purpose = "Database"
   }
}


