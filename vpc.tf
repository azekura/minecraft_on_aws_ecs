resource "aws_vpc" "ecs-default" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "10.0.0.0/16"
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    "Description" = "Created for ECS cluster default"
    "Name"        = "ECS default - VPC"
  }
}

resource "aws_internet_gateway" "ecs-default" {
  tags = {
    "Description" = "Created for ECS cluster default"
    "Name"        = "ECS default - InternetGateway"
  }
  vpc_id = aws_vpc.ecs-default.id
}

resource "aws_subnet" "ecs-default" {
  assign_ipv6_address_on_creation = false
  availability_zone               = var.aws-availability-zone
  cidr_block                      = "10.0.0.0/24"
  map_public_ip_on_launch         = false
  tags = {
    "Description" = "Created for ECS cluster default"
    "Name"        = "ECS default - Public Subnet 1"
  }
  vpc_id = aws_vpc.ecs-default.id

  timeouts {}
}

resource "aws_security_group" "ecs-default" {
  description = "ECS Allowed Ports"
  vpc_id      = aws_vpc.ecs-default.id

  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 25565
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 25565
    },
  ]

  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  tags = {
    "Description" = "Created for ECS cluster default"
    "Name"        = "ECS default - ECS SecurityGroup"
  }
}

resource "aws_security_group" "allow_nfs" {
  name        = "NFS"
  description = "NFS"
  vpc_id      = aws_vpc.ecs-default.id

  ingress = [
    {
      description      = ""
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      protocol         = "TCP"
      to_port          = "2049"
      from_port        = "2049"
      security_groups = [
        aws_security_group.ecs-default.id
      ]
    }
  ]

  egress = [
    {
      description      = ""
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      to_port          = "0"
      from_port        = "0"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
      security_groups = []
      self            = false
    }
  ]

  tags = {
    Name = "minecraft-on-ecs"
  }
}

resource "aws_security_group" "vpc-endpoint" {
  description = "VPCE Allowed Ports"
  vpc_id      = aws_vpc.ecs-default.id

  ingress = [
    {
      cidr_blocks = [
        aws_vpc.ecs-default.cidr_block,
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  tags = {
    "Description" = "VPCE Allowed Ports"
    "Name"        = "VPCE default - VPCE SecurityGroup"
  }
}


resource "aws_vpc_endpoint" "ecs_dkr" {
  vpc_id              = aws_vpc.ecs-default.id
  subnet_ids          = [aws_subnet.ecs-default.id]
  security_group_ids  = [aws_security_group.vpc-endpoint.id]
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs_api" {
  vpc_id              = aws_vpc.ecs-default.id
  subnet_ids          = [aws_subnet.ecs-default.id]
  security_group_ids  = [aws_security_group.vpc-endpoint.id]
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.ecs-default.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(aws_subnet.ecs-default)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_vpc.ecs-default.default_route_table_id
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.ecs-default.id
  subnet_ids          = [aws_subnet.ecs-default.id]
  security_group_ids  = [aws_security_group.vpc-endpoint.id]
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.ecs-default.id
  subnet_ids          = [aws_subnet.ecs-default.id]
  security_group_ids  = [aws_security_group.vpc-endpoint.id]
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}