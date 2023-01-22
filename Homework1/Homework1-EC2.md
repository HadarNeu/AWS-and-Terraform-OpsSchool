# Homework1 - Ec2
[The Assignment](https://github.com/ops-school/aws-basics/blob/master/assignments/ec2/assignment-1.md)
## More options for implementation of User Data as required:
(I imported a User Data file as a data resource which I rendered as you can see in main.tf)
1. User Data as a file- imported directly to the user_data configuration.
 ```sh
"${file("user_data.sh")}"
```
2. User Data as text- written directly with EOF command.
```sh
user_data = <<EOF
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
```
3. User Data as provisioner remote-exec:
```sh
  provisioner "file" {
    source      = "user_data.sh"
    destination = "/tmp/user_data.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/user_data.sh",
      "cd /tmp/"
      "./user_data.sh",
    ]
  }
```

