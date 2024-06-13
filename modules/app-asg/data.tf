data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "RHEL-9-DevOps-Practice"
  owners           = ["973714476881"]

}

#ami-05f020f5935e52dc4
#ff

data "vault_generic_secret" "ssh" {
  path = "common/common"
}