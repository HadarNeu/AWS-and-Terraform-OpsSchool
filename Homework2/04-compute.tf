resource "aws_instance" "webserver" {
   count = "${var.instance_count}"
   subnet_id = "${aws_subnet.private[count.index].id}"
   instance_type          = "${var.instance_type}"
   ami                    = "${var.aws_ami}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]  
   associate_public_ip_address = true
   user_data =  <<EOF
        #!/bin/bash
        sudo yum update -y
        sudo amazon-linux-extras install epel -y
        sudo amazon-linux-extras install nginx1 -y
        sudo chmod o+w /usr/share/nginx/html/index.html 
        sudo echo "<h1>Welcome to Grandpa's Whiskey</h1>" > /usr/share/nginx/html/index.html
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl start sshd
    EOF
    #These user data implementation ways did not work:
    # data "template_file" "user_data_file" {
   #   template = "${file("05-user_data.sh")}"

   # }
   #   user_data = "${file("05-user_data.sh")}"
   #user_data                   = "${data.template_file.user_data_file.rendered}"
  
   tags = {
       Name = "Webserver-EC2-${count.index+1}"
       Owner = "hadarNoy"
       Purpose = "Whiskey Website"
   }
}

resource "aws_instance" "db-server" {
   count = "${var.instance_count}"
   subnet_id = "${aws_subnet.private[count.index].id}"
   instance_type          = "${var.instance_type}"
   ami                    = "${var.aws_ami}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]  
  
   tags = {
       Name = "DBserver-EC2-${count.index+1}"
       Owner = "hadarNoy"
       Purpose = "Database"
   }
}


