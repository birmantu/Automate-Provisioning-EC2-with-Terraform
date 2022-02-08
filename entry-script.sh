#!/bin/bash
sudo yum update -y && yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx