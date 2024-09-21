############################################
##########          ALB Security Group
############################################
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "alb_sg"
  }
}

############################################
##########          ALB Setup
############################################
resource "aws_lb" "app_lb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    module.vpc.public_subnets[0],  # Public subnet in AZ1
    module.vpc.public_subnets[1],  # Public subnet in AZ2
  ]

  enable_deletion_protection = false

  tags = {
    Name = "my-alb"
  }
}

############################################
##########          Target Groups
############################################

# Target Group for Flask (Port 5001)
resource "aws_lb_target_group" "flask_tg" {
  name        = "flask-tg"
  port        = 5001  # Flask app is listening on port 5001
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/app"
    protocol            = "HTTP"
    port                = "5001"  # Ensure health checks run on port 5001
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "flask-tg"
  }
}

# Target Group for Grafana (Port 3000)
resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000  # Grafana listens on port 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/login"
    protocol            = "HTTP"
    port                = "3000"  # Ensure health checks run on port 3000
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "grafana-tg"
  }
}

############################################
##########          ALB Listener
############################################

# ALB Listener for HTTP traffic on port 80
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn  # Default route to Flask app
  }
}

# Listener Rule for Grafana (Port 3000)
resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100  # Higher priority than the default for Grafana

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    path_pattern {
      values = ["/login"]  # Grafana will be accessible via /grafana/*
    }
  }
}

############################################
##########          Target Group Attachments
############################################

# Attach Flask instances to Flask target group
resource "aws_lb_target_group_attachment" "flask_attachment_1" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = module.web_instance["instance-private-1"].id
  port             = 5001  # Flask runs on port 5001
}

resource "aws_lb_target_group_attachment" "flask_attachment_2" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = module.web_instance["instance-private-2"].id
  port             = 5001  # Flask runs on port 5001
}

# Attach Grafana instance to Grafana target group
resource "aws_lb_target_group_attachment" "grafana_attachment" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = module.web_instance["instance-private-3"].id
  port             = 3000  # Grafana runs on port 3000
}






# resource "aws_s3_bucket" "my_bucket" {
#   bucket = "tomguedj-unique-s3-bucket"

#   # Add lifecycle block to ignore changes to object lock
#   lifecycle {
#     ignore_changes = [
#       object_lock_configuration
#     ]
#   }

#   tags = {
#     Name = "My S3 Bucket"
#   }
# }


# # Set the Bucket ACL to Public-Read
# resource "aws_s3_bucket_acl" "my_bucket_acl" {
#   bucket = aws_s3_bucket.my_bucket.id
#   acl    = "public-read"
# }

# # Upload the first image (theGOAT.jpeg)
# resource "aws_s3_object" "image1" {
#   bucket = aws_s3_bucket.my_bucket.bucket
#   key    = "theGOAT.jpeg"
#   source = "./images/theGOAT.jpeg"  # Adjust the path to the actual file location
#   acl    = "public-read"
# }

# # Upload the second image (thedip.jpeg)
# resource "aws_s3_object" "image2" {
#   bucket = aws_s3_bucket.my_bucket.bucket
#   key    = "thedip.jpeg"
#   source = "./images/thedip.jpeg"  # Adjust the path to the actual file location
#   acl    = "public-read"
# }

# # Upload the third image (warren.jpg)
# resource "aws_s3_object" "image3" {
#   bucket = aws_s3_bucket.my_bucket.bucket
#   key    = "warren.jpg"
#   source = "./images/warren.jpg"  # Adjust the path to the actual file location
#   acl    = "public-read"
# }