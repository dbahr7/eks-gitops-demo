# Network for the cluster, via the community VPC module (terraform-aws-modules/vpc/aws).

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.8"

  name                 = "${var.project}-vpc"
  cidr                 = "10.30.0.0/16"
  azs                  = local.azs
  private_subnets      = ["10.30.1.0/24", "10.30.2.0/24"]
  public_subnets       = ["10.30.101.0/24", "10.30.102.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  public_subnet_tags   = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags  = { "kubernetes.io/role/internal-elb" = 1 }
}
