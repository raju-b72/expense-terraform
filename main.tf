module "frontend" {
  depends_on = [module.backend]
  source = "./modules/app-asg"
  app_port = 80
  bastion_nodes = var.bastion_nodes
  component = "frontend"
  env = var.env
  instance_type = var.instance_type
  max_capacity = var.max_capacity
  min_capacity =var.min_capacity
  prometheus_nodes = var.prometheus_nodes
  server_app_port_sg_cidr = var.public_subnets
  subnets = module.vpc.frontend_subnets
  vpc_id = module.vpc.vpc_id
  vault_token = var.vault_token
  certificate_arn     = var.certificate_arn
  lb_app_port_sg_cidr = ["0.0.0.0/0"]
  lb_ports            = { http: 80, https: 443 }
#lb_subnets          = module.vpc.public_subnets
  lb_type             = "public"
  zone_id             = var.zone_id
}
# #
module "backend" {
  depends_on = [module.rds]
  source = "./modules/app-asg"
  app_port = 8080
  bastion_nodes = var.bastion_nodes
  component = "backend"
  env = var.env
  instance_type = var.instance_type
  max_capacity = var.max_capacity
  min_capacity =var.min_capacity
  prometheus_nodes = var.prometheus_nodes
  server_app_port_sg_cidr = concat(var.frontend_subnets, var.backend_subnets)
  subnets = module.vpc.backend_subnets
  vpc_id = module.vpc.vpc_id
  vault_token = var.vault_token
  certificate_arn     = var.certificate_arn
  lb_app_port_sg_cidr = var.frontend_subnets
  lb_ports            = { http: 8080 }
  lb_subnets          = module.vpc.backend_subnets
  lb_type             = "private"
  zone_id             = var.zone_id
}
# #
# #
#
#  module "mysql" {
#    source = "./modules/app"
#    instance_type = var.instance_type
#    component = "mysql"
#    env = var.env
#    zone_id = var.zone_id
#    vault_token = var.vault_token
#    subnets = module.vpc.db_subnets
#    vpc_id = module.vpc.vpc_id
#     bastion_nodes = var.bastion_nodes
#     prometheus_nodes = var.prometheus_nodes
#    app_port = 3306
#    server_app_port_sg_cidr = var.backend_subnets              #which security group i want to allw
#
#  }
#

 module "rds" {
   source = "./modules/rds"
   allocated_storage    = 20
   component             = "rds"
   engine               = "mysql"
   engine_version       = "8.0.36"
   env                 = var.env
   family               = "mysql8.0"
   instance_class       = "db.t3.micro"
   server_app_port_sg_cidr = var.backend_subnets
   skip_final_snapshot  = true
   storage_type =   "gp3"
   subnet_ids = module.vpc.db_subnets
   vpc_id = module.vpc.vpc_id

#    kms_key_id = var.kms_key_id
 }

module "vpc" {
  source = "./modules/vpc"
  env = var.env
  vpc_cidr_block = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
   default_vpc_id = var.default_vpc_id
   default_vpc_cidr = var.default_vpc_cidr
   default_route_table_id = var.default_route_table_id
   frontend_subnets = var.frontend_subnets
   backend_subnets = var.backend_subnets
   db_subnets = var.db_subnets
   public_subnets = var.public_subnets
   availability_zones = var.availability_zones
}