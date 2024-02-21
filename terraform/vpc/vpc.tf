provider "aws" {
    region = "var.region" 
  
}
terraform {
  backend "s3" {}
}

resource "aws_vps" "noteapp-vpc" {
  cidr_block = "var.vpc_cidr"
  enable_dns_hostnames = true

  tags = {
    Name = "noteapp-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  cidr_block = "var.public_subnet_1_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1a"

    tags = {
        Name = "noteapp-public-subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2" {
  cidr_block = "var.public_subnet_2_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1b"

    tags = {
        Name = "noteapp-public-subnet-2"
    }
}

resource "aws_subnet" "public_subnet_3" {
  cidr_block = "var.public_subnet_3_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1c"

    tags = {
        Name = "noteapp-public-subnet-3"
    }
}


resource "aws_subnet" "private_subnet_1" {
  cidr_block = "var.private_subnet_1_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1a"

    tags = {
        Name = "noteapp-private-subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
  cidr_block = "var.private_subnet_2_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1b"

    tags = {
        Name = "noteapp-private-subnet-2"
    }
}

resource "aws_subnet" "private_subnet_3" {
  cidr_block = "var.private_subnet_3_cidr"
  vpc_id = "aws_vpc.noteapp-vpc.id"
  availability_zone = "us-east-1c"

    tags = {
        Name = "noteapp-private-subnet-3"
    }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = "aws_vpc.noteapp-vpc.id"
  tags = {
    Name = "noteapp-public-route-table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = "aws_vpc.noteapp-vpc.id"
  tags = {
    Name = "noteapp-private-route-table"
  }
}

resource "aws_route_table_association" "public-subnet-1-association" {
  subnet_id = "aws_subnet.public_subnet_1.id"
  route_table_id = "aws_route_table.public-route-table.id"
}

resource "aws_route_table_association" "public-subnet-2-association" {
  subnet_id = "aws_subnet.public_subnet_2.id"
  route_table_id = "aws_route_table.public-route-table.id"
}

resource "aws_route_table_association" "public-subnet-3-association" {
  subnet_id = "aws_subnet.public_subnet_3.id"
  route_table_id = "aws_route_table.public-route-table.id"
}

resource "aws_route_table_association" "private-subnet-1-association" {
  subnet_id = "aws_subnet.private_subnet_1.id"
  route_table_id = "aws_route_table.private-route-table.id"
}

resource "aws_route_table_association" "private-subnet-2-association" {
  subnet_id = "aws_subnet.private_subnet_2.id"
  route_table_id = "aws_route_table.private-route-table.id"
}

resource "aws_route_table_association" "private-subnet-3-association" {
  subnet_id = "aws_subnet.private_subnet_3.id"
  route_table_id = "aws_route_table.private-route-table.id"
}

resource "aws_eip" "eip-nat-gw" {
  domain = "vpc"
  associate_with_private_ip = "10.0.0.5"

  tags =  {
    Name = "noteapp-eip"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = "aws_eip.eip-nat-gw.id"
  subnet_id = "aws_subnet.public_subnet_1.id"

  tags = {
    Name = "noteapp-nat-gateway"
  }
  depends_on = [aws_eip.eip-nat-gw]
}

resource "aws_route" "nat-gw-route" {
  route_table_id = "aws_route_table.private-route-table.id"
  nat_gateway_id = "aws_nat_gateway.nat-gateway.id"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_internet_gateway" "noteapp-igw" {
  vpc_id = "aws_vpc.noteapp-vpc.id"

  tags = {
    Name = "noteapp-internet-gateway"
  }
}

resource "aws_route" "igw-route" {
  route_table_id = "aws_route_table.public-route-table.id"
  gateway_id = "aws_internet_gateway.noteapp-igw.id"
  destination_cidr_block = "0.0.0.0/0"
}
