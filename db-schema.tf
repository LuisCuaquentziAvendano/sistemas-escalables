resource "aws_instance" "db_initializer" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable corretto8
    yum install -y mysql

    until mysql -h ${aws_db_instance.mysql.endpoint} -u ${var.db_username} -p${var.db_password} -e "SELECT 1;" &> /dev/null; do
      echo "Waiting for RDS..."
      sleep 10
    done

    mysql -h ${aws_db_instance.mysql.endpoint} -u ${var.db_username} -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    mysql -h ${aws_db_instance.mysql.endpoint} -u ${var.db_username} -p${var.db_password} ${var.db_name} -e "
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
  EOF
  )

  tags = { Name = "db-initializer" }
}
