resource "aws_db_instance" "main" {
  identifier           = "${var.component}-${var.env}"
  db_name              = "mydb"
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = jsondecode(data.vault_generic_secret.rds.data_json).rds_username
  password             = jsondecode(data.vault_generic_secret.rds.data_json).rds_password
  parameter_group_name = aws_db_parameter_group.main.name
  skip_final_snapshot  = var.skip_final_snapshot
  multi_az = false
  allocated_storage    = var.allocated_storage
  storage_type = var.storage_type
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.main.id]
  storage_encrypted = true                                     #encryption(kms key)
  kms_key_id = var.kms_key_id
  backup_retention_period = 35                                 #for enabling backup in dtabase
  backup_window = "07:00-08:00"
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.component}-${var.env}-pg"
  family = var.family
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.component}-${var.env}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.component}-${var.env}-subnet-group"
  }
}

resource "aws_security_group" "main" {
  name = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id


  ingress {                                          #one is inboundport/any sg wii have inbound rules and outbound rules
    from_port        = 3306
    to_port          = 3306                  #0 to 0 is whole range
    protocol         = "TCP"                          #this stands for all traffic(-1)
    cidr_blocks      = var.server_app_port_sg_cidr
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
