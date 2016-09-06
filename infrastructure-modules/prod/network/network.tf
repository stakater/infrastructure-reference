module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules"

    vpc_cidr = "10.3.0.0/16"
    name = "${var.stack_name}-prod"

    public_subnets = ["10.3.71.0/24", "10.3.72.0/24", "10.3.73.0/24", "10.3.74.0/24", "10.3.75.0/24", "10.3.76.0/24"]
    private_app_subnets =  ["10.3.31.0/24", "10.3.32.0/24", "10.3.33.0/24", "10.3.34.0/24", "10.3.35.0/24", "10.3.36.0/24"]
    private_persistence_subnets =  ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24", "10.3.4.0/24", "10.3.5.0/24", "10.3.6.0/24"]

    azs =  "${var.availability_zones}"
}