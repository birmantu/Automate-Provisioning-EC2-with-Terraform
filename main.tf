provider "aws" {
    region = "ap-south-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

resource "aws_vpc" "my-cutom-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "my-custom-subnet1"{
    vpc_id = aws_vpc.my-cutom-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet1"
    }
}

resource "aws_internet_gateway" "my-custom-igw"{
    vpc_id = aws_vpc.my-cutom-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

/* resource "aws_route_table" "my-custom-route-table"{
    vpc_id = aws_vpc.my-cutom-vpc.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-custom-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-rtb"
    }
} */

/* resource "aws_route_table_association" "a-rtb-subnet"{
     subnet_id = aws_subnet.my-custom-subnet1.id
     route_table_id = aws_route_table.my-custom-route-table.id
} */

resource "aws_default_route_table" "main-rtb"{
    default_route_table_id = aws_vpc.my-cutom-vpc.default_route_table_id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-custom-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}

resource "aws_security_group" "my-custom-sg"{
    name = "my-custom-sg"
    vpc_id = aws_vpc.my-cutom-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "latest_amazon_linux_image"{
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-*_64-gp2"]
    } 
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "amazon_ami_id" {
    value = data.aws_ami.latest_amazon_linux_image.id
}

resource "aws_key_pair" "ssh-key"{
    key_name = "server-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server"{
    ami = data.aws_ami.latest_amazon_linux_image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.my-custom-subnet1.id
    vpc_security_group_ids = [aws_security_group.my-custom-sg.id]

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

user_data = file("entry-script.sh")

    tags = {
        Name = "${var.env_prefix}-server"
    }
}