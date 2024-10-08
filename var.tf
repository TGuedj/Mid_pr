variable "AWS_REGION" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "The AWS vpc name"
  type        = string
  default     = "sample"

}

variable "vpc_cidr" {
  description = "The AWS vpc cidr block"
  type        = string
  default     = "10.0.0.0/16"

}


variable "instance_names" {
  type    = list(string)
  default = ["instance-private-1", "instance-private-2", "instance-private-3"]
}




resource "aws_security_group" "instance_sg" {
  name        = "instance_security_group"
  description = "Allow inbound traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP traffic from ALB's security group
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Reference ALB SG
    description     = "Allow HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance_sg"
  }
}

# Attach the security group to the instances





variable "instances" {
  type = map(object({
    user_data = string
  }))
  default = {
    "instance-private-1" = {
      user_data = <<-EOF
      #!/bin/bash

      # Update the system packages
      yum update -y

      # Install Docker
      yum install -y docker

      # Start and enable Docker service
      service docker start
      chkconfig docker on

      # Pull the Docker image
      sudo docker pull tom621/half_project:latest

      # Remove existing container if any
      sudo docker rm -f half_project

      # Run the Docker container
      sudo docker run -d --name=half_project -p 5001:5001 tom621/half_project:latest


      EOF
    }
    "instance-private-2" = {
      user_data = <<-EOF
      #!/bin/bash

      # Update the system packages
      yum update -y

      # Install Docker
      yum install -y docker

      # Start and enable Docker service
      service docker start
      chkconfig docker on

      # Pull the Docker image
      sudo docker pull tom621/half_project:latest

      # Remove existing container if any
      sudo docker rm -f half_project

      # Run the Docker container
      sudo docker run -d --name=half_project -p 5001:5001 tom621/half_project:latest


      EOF
    }
    "instance-private-3" = {
      user_data = <<-EOF
      #!/bin/bash

      # Update the system packages
      yum update -y

      # Install Docker
      yum install -y docker

      # Start and enable Docker service
      service docker start
      chkconfig docker on

      # Pull the Grafana Docker image
      sudo docker pull grafana/grafana

      # Create Docker volume
      sudo docker volume create mydata

      # Remove existing Grafana container if any
      sudo docker rm -f grafana

      # Run the Grafana Docker container with data volume
      sudo docker run -d --name=grafana -p 3000:3000 --mount source=mydata,target=/var/lib/grafana grafana/grafana


        
      EOF
    }
  }
}
