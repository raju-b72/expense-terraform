data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "RHEL-9-DevOps-Practice"
  owners           = ["973714476881"]

}
data "aws_security_group" "selected" {
  name = "allow-all"
}