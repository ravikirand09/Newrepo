
provider "aws" {
  version    = "~> 0.14"
  region     = "us-west"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet"
  }
}

resource "aws_instance" "my_instance" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  tags = {
    Name = "Web instance"
  }
}

resource "aws_security_group" "alb" {
  name        = "terraform_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "terraform-example-alb-security-group"
  }
}
Create a new application load balancer:

resource "aws_alb" "alb" {
  name            = "terraform-example-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.main.*.id}"]
  tags {
     Name = "terraform-example-alb"
  }
}


resource "aws_alb_target_group" "group" {
  name     = "terraform-example-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/login"
    port = 80
  }
}
 

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}
    
