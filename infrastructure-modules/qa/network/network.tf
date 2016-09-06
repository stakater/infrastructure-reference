module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules"

    vpc_cidr = "10.2.0.0/16"
    name = "${var.stack_name}-qa"

    public_subnets = ["10.2.71.0/24", "10.2.72.0/24", "10.2.73.0/24", "10.2.74.0/24", "10.2.75.0/24", "10.2.76.0/24"]
    private_app_subnets =  ["10.2.31.0/24", "10.2.32.0/24", "10.2.33.0/24", "10.2.34.0/24", "10.2.35.0/24", "10.2.36.0/24"]
    private_persistence_subnets =  ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]

    azs =  "${var.availability_zones}"
}