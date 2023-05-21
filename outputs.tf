## In Terraform, an "outputs.tf" file is used to define outputs that are generated as a result of deploying your infrastructure with Terraform. O

output "elb_address" {
  value = aws_elb.web.dns_name
}

output "addresses" {
  value = aws_instance.web[*].public_ip
}

output "public_subnet_id" {
  value = module.vpc_basic.public_subnet_id
}

