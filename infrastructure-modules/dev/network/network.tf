module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules?ref=vpc-peering"

    vpc_cidr = "10.1.0.0/16"
    name = "${var.stack_name}-dev"

    public_subnets = ["10.1.71.0/24", "10.1.72.0/24", "10.1.73.0/24", "10.1.74.0/24", "10.1.75.0/24", "10.1.76.0/24"]
    private_app_subnets =  ["10.1.31.0/24", "10.1.32.0/24", "10.1.33.0/24", "10.1.34.0/24", "10.1.35.0/24", "10.1.36.0/24"]
    private_persistence_subnets =  ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24", "10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]

    azs =  "${var.availability_zones}"
}

output "vpc_cidr" {
  value = "${module.network.vpc_cidr}"
}