data "aws_secretsmanager_secret" "db_credentials" {
  count = var.enable_rds ? 1 : 0
  name  = "clinic/db-credentials-${var.environment}"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.enable_rds ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.db_credentials[0].id
}

locals {
  db_credentials = var.enable_rds ? jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string) : {
    dbname   = ""
    username = ""
    password = ""
  }
  rds_identifier = "${var.environment}-${var.db_identifier}"
}
