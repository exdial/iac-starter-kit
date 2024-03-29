# This module standardizes the output of existing AWS resources

data "aws_vpc" "default" {
  default = true
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "default_subnet_ids" {
  value = data.aws_subnets.default.ids
}
