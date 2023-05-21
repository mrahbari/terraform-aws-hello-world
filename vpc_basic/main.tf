## This block creates an AWS VPC (Virtual Private Cloud) resource named "tfb".
## It specifies the CIDR block for the VPC, DNS hostnames, DNS support, and tags.
resource "aws_vpc" "tfb" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = {
    Name = var.name
  }
}

## This block creates an internet gateway resource and attaches it to the VPC created in the previous step.
## It references the VPC ID using aws_vpc.tfb.id and assigns tags to the gateway.
resource "aws_internet_gateway" "tfb" {
  vpc_id = aws_vpc.tfb.id
  tags = {
    Name = "${var.name}-igw"
  }
}


## This block creates a route resource that enables internet access for the VPC.
## It specifies the route table ID (aws_vpc.tfb.main_route_table_id), the destination CIDR block (0.0.0.0/0), and the gateway ID (aws_internet_gateway.tfb.id).
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.tfb.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tfb.id
}

## This block creates a public subnet within the VPC.
## It references the VPC ID using aws_vpc.tfb.id and specifies the CIDR block for the subnet.
## The map_public_ip_on_launch parameter controls whether newly launched instances in the subnet are automatically assigned a public IP address.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.tfb.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = {
    Name = "${var.name}-public"
  }
}

