# module "frontend" {
#   depends_on = [module.backend]
#   source = "./modules/app"
#   instance_type= var.instance_type
#   component = "frontend"
#   env = var.env
#   zone_id = var.zone_id
#   vault_token = var.vault_token
# }
#
# module "backend" {
#   depends_on = [module.mysql]
#   source = "./modules/app"
#   instance_type= var.instance_type
#   component = "backend"
#   env = var.env
#   zone_id = var.zone_id
#   vault_token = var.vault_token
#
# }
#
#
# module "mysql" {
#   source = "./modules/app"
#   instance_type= var.instance_type
#   component = "mysql"
#   env = var.env
#   zone_id = var.zone_id
#   vault_token = var.vault_token
# }
#



# module "vpc" {
#   source = "./modules/vpc"
#   env = var.env
#   vpc_cidr_block = var.vpc_cidr_block
#   default_vpc_id = var.default_vpc_id
#   default_vpc_cidr = var.default_vpc_cidr