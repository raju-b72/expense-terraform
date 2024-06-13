env = "dev"
instance_type = "t3.micro"

zone_id = "Z1048539H590PER7RQKJ"

#
# #vpch
vpc_cidr_block = "10.10.0.0/24"
subnet_cidr_block = "10.10.0.0/24"
#
default_vpc_id = "vpc-026a7a8857566c08f"
default_vpc_cidr = "172.31.0.0/16"
default_route_table_id = "rtb-0d21ab4ee20e6524a"
frontend_subnets = ["10.10.0.0/27", "10.10.0.32/27"]
backend_subnets = ["10.10.0.64/27", "10.10.0.96/27"]
db_subnets = ["10.10.0.128/27", "10.10.0.160/27"]
public_subnets = ["10.10.0.192/27","10.10.0.224/27"]
availability_zones = ["us-east-1a", "us-east-1b"]
bastion_nodes = ["172.31.41.182/32"]
prometheus_nodes = ["172.31.35.105/32"]
certificate_arn = "arn:aws:acm:us-east-1:654654379173:certificate/b5f94dd1-f90b-43a9-bb9f-7a4107d4944a"
# kms_key_id = "arn:aws:kms:us-east-1:767397980724:key/1c299f73-8a2b-4cb1-9b87-491c91f5d48b"
#
# #asg
 max_capacity = 5
min_capacity = 1