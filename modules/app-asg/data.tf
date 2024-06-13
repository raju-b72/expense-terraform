data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "golden-ami-*"
  owners           = ["self"]

}

#ami-05f020f5935e52dc4
#ff

data "vault_generic_secret" "ssh" {
  path = "common/common"
}