variable "instance_type" {}
variable "component" {}
variable "env" {}
variable "zone_id" {}
variable "vault_token" {}
variable "vpc_id" {}
variable "subnets" {}
variable "lb_type" {       #we provide this because mysql will not fqil looing for value
  default = null
}
variable "lb_needed" {
  default = false
}
variable "lb_subnets" {
  default = null

}
variable "app_port"{
  default = null
}

variable "bastion_nodes" {}
variable "prometheus_nodes" {}
variable "server_app_port_sg_cidr" {}
variable "lb_app_port_sg_cidr" {
  default = []
}
variable "certificate_arn" {
  default = null
}

variable "lb_ports" {
  default = {}
}

# variable "kms_key_id" {}