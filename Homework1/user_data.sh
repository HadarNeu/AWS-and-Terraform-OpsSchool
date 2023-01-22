#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install epel -y
sudo amazon-linux-extras install nginx1 -y
sudo chmod o+w /usr/share/nginx/html/index.html 
sudo echo "<h1>Welcome to Grandpa's Whiskey</h1>" > /usr/share/nginx/html/index.html
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl start sshd
