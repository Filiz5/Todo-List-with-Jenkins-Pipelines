terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

provider "aws" {
  # Configuration options
  # access ve secret
  region = "us-east-1"
}
variable "key" {
  default = "jenkins-project"
}

variable "user" {
  default = "techpro"
}

resource "aws_instance" "managed_nodes" {
  ami = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name = var.key
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  iam_instance_profile = "jenkins-project-profile-${var.user}"
  tags = {
    Name = "jenkins_project"
  }
}


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

output "node_public_ip" {
  value = aws_instance.managed_nodes.public_ip
}