#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo service nginx start
echo "Hello, World!" > /var/www/html/index.html

