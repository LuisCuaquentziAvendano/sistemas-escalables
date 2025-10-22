resource "aws_instance" "db_initializer" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags                   = { Name = "db-initializer" }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/db-init.log 2>&1
    echo "Starting DB initialization"
    dnf update -y
    dnf install -y mariadb105
    echo "Running: mysql -h ${aws_rds_cluster.mysql_cluster.endpoint} -u ${var.db_username} -p${var.db_password} -e 'SELECT 1;'"

    until mysql -h ${aws_rds_cluster.mysql_cluster.endpoint} -u ${var.db_username} -p${var.db_password} -e "SELECT 1;" &> /dev/null; do
      echo "Waiting for RDS at $(date)..."
      sleep 10
    done

    echo "Creating database..."
    mysql -h ${aws_rds_cluster.mysql_cluster.endpoint} -u ${var.db_username} -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    echo "Creating table..."
    mysql -h ${aws_rds_cluster.mysql_cluster.endpoint} -u ${var.db_username} -p${var.db_password} ${var.db_name} -e "${var.db_schema}"
    echo "DB initialization completed"
  EOF
}
