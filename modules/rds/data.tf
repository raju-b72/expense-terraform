data "vault_generic_secret" "rds" {
  path = "rds/${var.env}"
}