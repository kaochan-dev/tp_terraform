
provider "aws" {
  region = var.region
}

resource "aws_vpc" "sra_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sra_subnet_a" {
  vpc_id                  = aws_vpc.sra_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az1
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sra_subnet_b" {
  vpc_id                  = aws_vpc.sra_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az2
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "sra_igw" {
  vpc_id = aws_vpc.sra_vpc.id
}

resource "aws_route_table" "sra_rt" {
  vpc_id = aws_vpc.sra_vpc.id
}

resource "aws_route" "sra_default" {
  route_table_id         = aws_route_table.sra_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sra_igw.id
}

resource "aws_route_table_association" "sra_rta_a" {
  subnet_id      = aws_subnet.sra_subnet_a.id
  route_table_id = aws_route_table.sra_rt.id
}

resource "aws_route_table_association" "sra_rta_b" {
  subnet_id      = aws_subnet.sra_subnet_b.id
  route_table_id = aws_route_table.sra_rt.id
}

resource "aws_security_group" "sra_sg" {
  name        = "sra-sg"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.sra_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "sra_alb" {
  name               = "sra-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sra_sg.id]
  subnets            = [aws_subnet.sra_subnet_a.id, aws_subnet.sra_subnet_b.id]
}

resource "aws_lb_target_group" "sra_tg" {
  name     = "sra-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sra_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "sra_listener" {
  load_balancer_arn = aws_lb.sra_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sra_tg.arn
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "sra_lt" {
  name_prefix   = "sra-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sra_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>Instance ID: $INSTANCE_ID</h1>" > /var/www/html/index.html
EOF
  )
}

resource "aws_autoscaling_group" "sra_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.sra_subnet_a.id, aws_subnet.sra_subnet_b.id]
  target_group_arns    = [aws_lb_target_group.sra_tg.arn]
  health_check_type    = "EC2"

  launch_template {
    id      = aws_launch_template.sra_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "sra_Instance"
    propagate_at_launch = true
  }
}
