#VPC Resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
    enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

#Internet Gateway Resource
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.name
  }
}

#Public Subnet
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = var.name
  }
}

#Route Table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.name
  }
}

#Route table + PS Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

