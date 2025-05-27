terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
      }
    }
}

provider "aws" {
  region = "us-east-1"
}

# Networking
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-example"
  }
}
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-example"
  }
}
resource "aws_network_interface" "my_interface" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.my_interface.id
    device_index         = 0
  }

  tags = {
    Name = "Ubuntu AMI"
  }
}

# EFS Volume
resource "aws_efs_file_system" "my_efs_vol_123" {
  creation_token = "my_efs_vol"

  tags = {
    Name = "My EFS Volume"
  }
}
resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.my_efs_vol_123.id
}
resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.my_efs_vol_123.id
  subnet_id      = aws_subnet.my_subnet.id
}
