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


resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]                        #we created our own security group
  subnet_id = var.subnets[0]                                                 #we give first subnet
#   root_block_device {
#     encrypted  = true
#     kms_key_id = var.kms_key_id
#   }
  #12


  tags = {
    Name = var.component
    monitor = "yes"
    env = var.env
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }

}





resource "null_resource" "ansible" {      # but can be used to trigger actions through provisioners or local-exec #THIS HAS NO INHERENT PROPERTIES  triggers
  triggers = {
    instance = aws_instance.instance.id
  }
  connection {
    type     = "ssh"
    user     = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_user
    password = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_password
    host     = aws_instance.instance.private_ip
  }

  provisioner "remote-exec" {

    inline = [
      "rm -f ~/*.json",
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost, -U https://github.com/raju-b71/expense-ansible get-secrets.yml -e env=${var.env} -e role_name=${var.component} -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/raju-b71/expense-ansible expense.yml -e env=${var.env} -e role_name=${var.component} -e @~/secrets.json",


    ]
  }
  provisioner "remote-exec" {
    inline = [
      "rm -f ~/secrets.json ~/app.json"
    ]
  }
}

#routw53 records for server and loadbalancer..
resource "aws_route53_record" "server" {
  count = var.lb_needed ? 0 : 1
  name    = "${var.component}-${var.env}"
  type    = "A"
  zone_id = var.zone_id
  records = [aws_instance.instance.private_ip]
  ttl = 30
}

resource "aws_route53_record" "load-balancer" {                   #route53 for lb
  count  = var.lb_needed ? 1 : 0                                       #  if lb is needed then we create server record = 1
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  zone_id = var.zone_id
  records = [aws_lb.main[0].dns_name]
  ttl = 30
}

#security group for LOADBALANCER
resource "aws_security_group" "load-balancer" {                   #seperate sg for loadbalancer
  count = var.lb_needed ? 1 : 0
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
  count = var.lb_needed ? 1 : 0                                           #this is condition because mysql is failing for not having lb
  name               = "${var.env}-${var.component}-alb"
  internal           = var.lb_type == "public" ? false : true              #this  is cond if var.lb= public is false then
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer[0].id]
  subnets            = var.lb_subnets                                       # we have to go to f,b and choose subnets

  tags = {
    Environment = "${var.env}-${var.component}-alb"
  }
}

#LOADBALANCER TARGET GROUP()
resource "aws_lb_target_group" "main" {                                  #this is target group before giving listener
  count = var.lb_needed ? 1 : 0
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


#LOADBALANCER TARGET GROUP ATTACHMENT
resource "aws_lb_target_group_attachment" "main" {                       #creating attach group for target group
  count = var.lb_needed ? 1 : 0
  target_group_arn = aws_lb_target_group.main[0].arn
  target_id        = aws_instance.instance.id
  port             = var.app_port
}


#LOADBALANCER LISTENER
resource "aws_lb_listener" "frontend-http" {                                  #listener group
  count = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
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
  count = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

}

resource "aws_lb_listener" "backend" {                                  #listener group
  count = var.lb_needed && var.lb_type != "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

#