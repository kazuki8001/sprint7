provider "aws" {
  region = "ap-northeast-1"
}

# VPC作成
resource "aws_vpc" "terra-vpc" {
  cidr_block = "10.0.8.0/21"
  tags = {
    Name = "terra-reservation-vpc"
  }
}

# サブネット作成（パブリック）
resource "aws_subnet" "terra-subnet-web" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.8.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "terra-web-subnet-01"
  }
}

resource "aws_subnet" "terra-subnet-elb-a" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.9.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "terra-elb-subnet-01"
  }
}
 
resource "aws_subnet" "terra-subnet-elb-c" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "terra-elb-subnet-02"
  }
}

# サブネット作成（プライベート）
resource "aws_subnet" "terra-subnet-api-a" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terra-api-subnet-01"
  }
}

resource "aws_subnet" "terra-subnet-api-c" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "terra-api-subnet-02"
  }
}

resource "aws_subnet" "terra-subnet-rds-a" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.13.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terra-rds-subnet-01"
  }
}

resource "aws_subnet" "terra-subnet-rds-c" {
  vpc_id = aws_vpc.terra-vpc.id
  cidr_block = "10.0.14.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "terra-rds-subnet-02"
  }
}

# インターネットゲートウェイ作成
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "terra-reservation-ig"
  }
}

# NATゲートウェイ用のElastic IPを確保
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gatewayを作成
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.terra-subnet-web.id
}

# ルートテーブル作成（パブリック）
resource "aws_route_table" "rt-web" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }

  tags = {
    Name = "terra-web-routetable"
  }
}

resource "aws_route_table_association" "rt-elb-a" {
  subnet_id = aws_subnet.terra-subnet-elb-a.id
  route_table_id = aws_route_table.rt-web.id
}

resource "aws_route_table_association" "rt-elb-c" {
  subnet_id = aws_subnet.terra-subnet-elb-c.id
  route_table_id = aws_route_table.rt-web.id
}

resource "aws_route_table_association" "rt-web-a" {
  subnet_id = aws_subnet.terra-subnet-web.id
  route_table_id = aws_route_table.rt-web.id
}

# ルートテーブル作成（プライベート）
resource "aws_route_table" "rt-api" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "terra-api-routetable"
  }
}

resource "aws_route_table_association" "rt-api-a" {
  subnet_id = aws_subnet.terra-subnet-api-a.id
  route_table_id = aws_route_table.rt-api.id  
}

resource "aws_route_table_association" "rt-api-c" {
  subnet_id = aws_subnet.terra-subnet-api-c.id
  route_table_id = aws_route_table.rt-api.id  
}

# ルートテーブル作成（プライベート）
resource "aws_route_table" "rt-rds" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "terra-rds-routetable"
  }
}

resource "aws_route_table_association" "rt-rds-a" {
  subnet_id = aws_subnet.terra-subnet-rds-a.id
  route_table_id = aws_route_table.rt-rds.id
}

resource "aws_route_table_association" "rt-rds-c" {
    subnet_id = aws_subnet.terra-subnet-rds-c.id
    route_table_id = aws_route_table.rt-rds.id
}

# セキュリティグループ作成
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.terra-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra-web-sg"
  }
}

resource "aws_security_group" "elb_sg" {
  vpc_id = aws_vpc.terra-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra-elb-sg"
  }
}

resource "aws_security_group" "api_sg" {
  vpc_id = aws_vpc.terra-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.elb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra-api-sg"
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.terra-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra-db-sg"
  }
}

#EC2作成（Webサーバ）
resource "aws_instance" "web_server" {
  ami           = "ami-08745a8fb272a61f2"
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.terra-subnet-web.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "terra-web-server-01"
  }
}

# 起動テンプレートで起動するEC2インスタンスがこのIAMロールを引き受けられるようにする（SSMでログインするため）
resource "aws_iam_role" "ssm_role" {
  name = "terra-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# AmazonSSMManagedInstanceCore のマネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#ロールをインスタンスに紐づけるための設定
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# 起動テンプレート作成（APIサーバ）
resource "aws_launch_template" "api_launch_template" {
  image_id      = "ami-078f615f0d851c837"
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.api_sg.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terra-api-launch-template"
    }
  }
}

# ALB作成
resource "aws_lb" "api_alb" {
  name               = "terra-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.terra-subnet-elb-a.id, aws_subnet.terra-subnet-elb-c.id]
}

# ターゲットグループ作成
resource "aws_lb_target_group" "alb_tg" {
  name     = "terra-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terra-vpc.id
}

# リスナー作成
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = "80"
  protocol         = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# Auto Scaling Group作成
resource "aws_autoscaling_group" "alb_asg" {
    desired_capacity = 2
    min_size = 2
    max_size = 4
    vpc_zone_identifier = [aws_subnet.terra-subnet-api-a.id,aws_subnet.terra-subnet-api-c.id]
    target_group_arns = [aws_lb_target_group.alb_tg.arn]
    launch_template {
      id = aws_launch_template.api_launch_template.id
      version = "$Latest"
    }
    health_check_type = "ELB"
    health_check_grace_period = 300
    force_delete = true
    wait_for_capacity_timeout = "0"
}

# ターゲット追跡スケーリングポリシー作成
resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.alb_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value       = 80.0
    disable_scale_in   = false 
  }
}

# Secrets Manager を参照
data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = "teraa/credentials"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)
}

# サブネットグループ作成
resource "aws_db_subnet_group" "rds_subnet_gr" {
  name       = "terra-subnet-group"
  subnet_ids = [aws_subnet.terra-subnet-rds-a.id,aws_subnet.terra-subnet-rds-c.id]
}

# RDS作成
resource "aws_db_instance" "rds_db" {
  identifier              = "terra-db-1"
  engine                  = "mysql"
  engine_version          = "8.0.41"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  username = local.db_creds.username
  password = local.db_creds.password
  db_name                 = "terradb1"
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_gr.name
}
