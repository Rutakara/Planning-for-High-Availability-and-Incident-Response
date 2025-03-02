variable primary_db_cluster_arn {}
variable primary_db_cluster_instance_arn {}

resource "aws_rds_cluster_parameter_group" "cluster_pg-s" {
  name   = "udacity-pg-s"
  family = "aurora-mysql5.7"

  parameter {
    name  = "binlog_format"    
    value = "MIXED"
    apply_method = "pending-reboot"
  }

  parameter {
    name = "log_bin_trust_function_creators"
    value = 1
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "udacity_db_subnet_group" {
  name       = "udacity_db_subnet_group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_rds_cluster" "udacity_cluster-s" {
  engine                   = "aurora-mysql"
  cluster_identifier       = "udacity-db-cluster-s"
  availability_zones       = ["us-west-1b","us-west-1a"]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_pg-s.name
  vpc_security_group_ids   = [aws_security_group.db_sg_2.id]
  db_subnet_group_name     = aws_db_subnet_group.udacity_db_subnet_group.name
  engine_mode              = "provisioned"
  engine_version           = "5.7.mysql_aurora.2.11.2" 
  replication_source_identifier = var.primary_db_cluster_arn
  source_region            = "us-east-2"
  backup_retention_period  = 5
  skip_final_snapshot      = true
  storage_encrypted        = false
  depends_on = [var.primary_db_cluster_instance_arn, aws_rds_cluster_parameter_group.cluster_pg-s]
}

resource "aws_rds_cluster_instance" "udacity_instance-s" {
  count                = 2
  engine               = "aurora-mysql"
  identifier           = "udacity-db-instance-${count.index}-s"
  cluster_identifier   = aws_rds_cluster.udacity_cluster-s.id
  instance_class       = "db.t2.small"
  db_subnet_group_name = aws_db_subnet_group.udacity_db_subnet_group.name
}

resource "aws_security_group" "db_sg_2" {
  name   = "udacity-db-sg"
  vpc_id =  var.vpc_id

  ingress {
    from_port   = 3306
    protocol    = "TCP"
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    protocol    = "TCP"
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }
}