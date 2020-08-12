provider "aws" {
  version = "~> 2.61"
}

variable "default_tags" {
  type = map
  default = {
    Env = "Demo"
    App = "Query Browser"
    FromTerraform = "true"
    Talk = "AWS UG Surabaya #06"
  }
}

resource "aws_security_group" "mysql" {
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.default_tags
}

resource "aws_db_instance" "mysql_rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "serverlessphp"
  username             = "awsug"
  password             = "surabaya200815"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.mysql.id]
}

output "database" {
  value = {
    endpoint = aws_db_instance.mysql_rds.endpoint
    engine = "${aws_db_instance.mysql_rds.engine} ${aws_db_instance.mysql_rds.engine_version}"
    connect = "mysql -u ${aws_db_instance.mysql_rds.username} -h ${aws_db_instance.mysql_rds.address} -p ${aws_db_instance.mysql_rds.name}"
  }
}