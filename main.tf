## This block configures the AWS provider for Terraform and sets the region based on the value of the var.region variable.
provider "aws" {
  region = var.region
}

## This block represents the usage of a Terraform module named "vpc_basic" to create a basic VPC (Virtual Private Cloud) setup.
## It specifies the source of the module, which can be a local directory or a remote Git repository.
## Other input variables such as name, cidr, and public_subnet are passed to the module.
module "vpc_basic" {
  #source        = "github.com/mrahbari/vpc_basic_sample.git"
  source        = "./vpc_basic"
  name          = "web"
  cidr          = "10.0.0.0/16"
  public_subnet = "10.0.1.0/24"
}

## This block defines an AWS EC2 instance resource named "web".
## It specifies the AMI (Amazon Machine Image), instance type, subnet ID, private IP, user data script, security groups, and tags for the instance.
## The count parameter indicates that multiple instances will be created based on the length of the var.instance_ips list.
## The associate_public_ip_address setting enables the instance to have a public IP address.
resource "aws_instance" "web" {
  ami                         = var.ami[var.region]
  instance_type               = var.instance_type
  #key_name                    = var.key_name
  subnet_id                   = module.vpc_basic.public_subnet_id
  private_ip                  = var.instance_ips[count.index]
  user_data                   = file("files/web_bootstrap.sh")
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.web_host_sg.id,
  ]

  tags = {
    Name = "web-mts-${format("%03d", count.index + 1)}"
  }

  count = length(var.instance_ips)
}

## This block creates an Elastic Load Balancer (ELB) resource named "web" to distribute traffic among the EC2 instances.
## It specifies the subnets and security groups for the ELB, as well as the listener configuration.
resource "aws_elb" "web" {
  name = "web-elb"
  subnets         = [module.vpc_basic.public_subnet_id]
  security_groups = [aws_security_group.web_inbound_sg.id]

  ## In the listener block, we define a listener for HTTP traffic on port 80.
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  ## A health check for the ELB in the health_check block.
  health_check {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  # The instances are registered automatically
  instances = aws_instance.web[*].id
}

## This block creates a security group resource named "web_inbound_sg" that allows inbound HTTP traffic from anywhere and ICMP traffic (ping).
## It specifies the ingress (incoming) and egress (outgoing) rules for the security group.
resource "aws_security_group" "web_inbound_sg" {
  name        = "web_inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = module.vpc_basic.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## This block creates a security group resource named "web_host_sg" that allows SSH and HTTP traffic from anywhere within the VPC and ICMP traffic (ping).
## It specifies the ingress and egress rules for the security group.
resource "aws_security_group" "web_host_sg" {
  name        = "web_host"
  description = "Allow SSH & HTTP to web hosts"
  vpc_id      = module.vpc_basic.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [module.vpc_basic.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
