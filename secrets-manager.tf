# command to force secret deletion
# aws secretsmanager delete-secret --secret-id Mydbsecret --force-delete-without-recovery

resource "aws_secretsmanager_secret" "db_secret" {
  name = "Mydbsecret"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    user     = var.db_username
    password = var.db_password
    host     = aws_db_instance.mysql.address
    db       = var.db_name
  })
}
