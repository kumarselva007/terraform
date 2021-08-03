provider "aws" {
  profile = "default"
  region  = "ap-south-1"
  access_key = "A3SIPQGO"
  secret_key = "2jy2nddF"
}


resource "aws_instance" "instance1" {

ami = "ami-04bde106886a53080"

instance_type = "t2.small"

subnet_id = "subnet-0c54f8e83b23989dd"


vpc_security_group_ids = module.http_sg.security_group_id


}


module "vote_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = "vpc-12345678"

  ingress_cidr_blocks      = ["10.10.0.0/16"]
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.10.0.0/16"
    },
      {
      from_port   = 443
      to_port     = 443 
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.10.0.0/16"
    },
 

    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"
  name = "education"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "subnet1" {
  name = "subnet1" 
  subnet_ids = module.vpc.public_subnets
 
}


resource "aws_db_instance" "rds1" {
  identifier = "rd1"
  instance_class = "db.t3.micro"
  allocated_storage = 5
  engine = "postgres"
  engine_version = "13.1"
  username = "edu"
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id] 
  parameter_group_name = aws_db_parameter_group.education.name
  publicly_accessible  = true 
  skip_final_snapshot  = true
}

resource "aws_db_parameter_group" "testrds" {
  name = "testrds"
  family = "postgres13"

  parameter {
    name = "log_connections"
    value = "1" 
 }

}


variable "db_password" {
  description = "RDS root user password" 
  type = string
  sensitive = true
}


resource "aws_s3_bucket" "onebucket" {
   bucket = "testing-s3"
   acl = "private"
   versioning {
      enabled = true
   }
   tags = {
     Name = "Bucket1"
     Environment = "Test"
   }
}
