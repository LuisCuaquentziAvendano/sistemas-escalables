resource "aws_instance" "db_initializer" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags                   = { Name = "db-initializer" }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/db-init.log 2>&1
    echo "Starting DB initialization"
    dnf update -y
    dnf install -y mariadb105
    echo "Running: mysql -h ${aws_db_instance.mysql.address} -u ${var.db_username} -p${var.db_password} -e 'SELECT 1;'"

    until mysql -h ${aws_db_instance.mysql.address} -u ${var.db_username} -p${var.db_password} -e "SELECT 1;" &> /dev/null; do
      echo "Waiting for RDS at $(date)..."
      sleep 10
    done

    echo "Creating database..."
    mysql -h ${aws_db_instance.mysql.address} -u ${var.db_username} -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    echo "Creating table..."
    mysql -h ${aws_db_instance.mysql.address} -u ${var.db_username} -p${var.db_password} ${var.db_name} -e "
      CREATE TABLE IF NOT EXISTS students(
        id INT NOT NULL AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL,
        address VARCHAR(255) NOT NULL,
        city VARCHAR(255) NOT NULL,
        state VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        phone VARCHAR(100) NOT NULL,
        PRIMARY KEY(id)
      );
    "
    echo "DB initialization completed"
  EOF
}
