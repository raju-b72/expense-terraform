resource "aws_security_group" "main" {
  name = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id


  ingress {                                          #one is inboundport/any sg wii have inbound rules and outbound rules
    from_port        = var.app_port
    to_port          = var.app_port                  #0 to 0 is whole range
    protocol         = "TCP"                          #this stands for all traffic(-1)
    cidr_blocks      = var.server_app_port_sg_cidr
  }

  ingress {
    from_port        = 22                             # 22 is for server port
    to_port          = 22
    protocol         = "TCP"                           #one is outboundport
    cidr_blocks      = var.bastion_nodes             #for bastian (workstation)only we allow ssh access
  }
  ingress {
    from_port        = 9100                        #same way for prometheus
    to_port          = 9100
    protocol         = "TCP"
    cidr_blocks      = var.prometheus_nodes
  }

  ingress {
    from_port        = 2019                      #same way for prometheus
    to_port          = 2019
    protocol         = "TCP"
    cidr_blocks      = var.prometheus_nodes
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


resource "aws_launch_template" "main" {
  name          = "${var.component}-${var.env}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    component   = var.component
    env         = var.env
    vault_token = var.vault_token
  }))
}


resource "aws_autoscaling_group" "main" {
  name          = "${var.component}-${var.env}"
  desired_capacity   = var.min_capacity
  max_size           = var.max_capacity
  min_size           = var.min_capacity
  vpc_zone_identifier = var.subnets
  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "monitor"
    value               = "yes"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = var.env
    propagate_at_launch = true
  }


}


resource "aws_autoscaling_policy" "main" {
  name                   = "target-cpu"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}


resource "aws_lb_target_group" "main" {                                  #this is target group before giving listener
  name     = "${var.env}-${var.component}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  deregistration_delay = 15

  health_check {
    healthy_threshold = 2
    interval = 5
    path = "/health"
    port = var.app_port
    timeout = 2
    unhealthy_threshold = 2


  }
}

#security group for LOADBALANCER
resource "aws_security_group" "load-balancer" {                   #seperate sg for loadbalancer
  name = "${var.component}-${var.env}-lb-sg"                        #name is loadbalancer security group
  description = "${var.component}-${var.env}-lb-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {                                         #one is inboundport/any sg wii have inbound rules and outbound rules
    for_each = var.lb_ports
    content {
      from_port   = ingress.value                              #0 to 0 is whole range
      to_port     = ingress.value
      protocol    = "TCP"                                     #this stands for all traffic
      cidr_blocks = var.lb_app_port_sg_cidr
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"                                         #one is outboundport
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

#THIS IS LOADBALANCER
resource "aws_lb" "main" {                                                     #loadbalncer

  name               = "${var.env}-${var.component}-alb"
  internal           = var.lb_type == "public" ? false : true              #this  is cond if var.lb= public is false then
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = var.lb_subnets                                       # we have to go to f,b and choose subnets

  tags = {
    Environment = "${var.env}-${var.component}-alb"
  }
}

resource "aws_route53_record" "load-balancer" {                   #route53 for lb#  if lb is needed then we create server record = 1
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  zone_id = var.zone_id
  records = [aws_lb.main.dns_name]
  ttl = 30
}

#LOADBALANCER LISTENER
resource "aws_lb_listener" "frontend-http" {                                  #listener group
  count =  var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "frontend-https" {                                  #listener group
  count =  var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

}

resource "aws_lb_listener" "backend" {                                  #listener group
  count = var.lb_type != "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}