resource "aws_db_subnet_group" "rds_private_subnets" {
  name       = "rds-private-subnet-group"
  subnet_ids = [for s in values(aws_subnet.private) : s.id]

  tags = {
    Name = "rds-private-subnet-group"
  }
}

resource "aws_rds_cluster" "mysql_cluster" {
  cluster_identifier     = "nodejs-mysql-cluster"
  engine                 = "aurora-mysql"
  engine_version         = var.db_engine
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_private_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "nodejs-mysql-cluster"
  }
}

resource "aws_rds_cluster_instance" "mysql_instances" {
  count                = 3
  identifier           = "nodejs-mysql-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.mysql_cluster.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.mysql_cluster.engine
  engine_version       = aws_rds_cluster.mysql_cluster.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.rds_private_subnets.name

  tags = {
    Name = "nodejs-mysql-${count.index + 1}"
  }
}
