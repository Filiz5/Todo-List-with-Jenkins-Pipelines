terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "key" {
  default = "jenkins-project"
}

variable "user" {
  default = "techpro"
}

# IAM Role ve Instance Profile Oluşturma
resource "aws_iam_role" "jenkins_project_role" {
  name = "jenkins-project-role-${var.user}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins_project_instance_profile" {
  name = "jenkins-project-profile-${var.user}"
  role = aws_iam_role.jenkins_project_role.name
}

# EC2 Instance Oluşturma
resource "aws_instance" "managed_nodes" {
  ami = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name = var.key
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_project_instance_profile.name
  tags = {
    Name = "jenkins_project"
  }
}

# Security Group
resource "aws_security_group" "tf-sec-gr" {
  name = "project-jenkins-sec-gr"
  tags = {
    Name = "project-jenkins-sec-gr"
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance'ın IP'sini Çıktı Olarak Verme
output "node_public_ip" {
  value = aws_instance.managed_nodes.public_ip
}
