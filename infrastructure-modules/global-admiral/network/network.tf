module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules"

    vpc_cidr = "10.0.0.0/16"
    name = "${var.stack_name}-global-admiral"

    public_subnets = ["10.0.71.0/24", "10.0.72.0/24", "10.0.73.0/24", "10.0.74.0/24", "10.0.75.0/24", "10.0.76.0/24"]
    private_app_subnets =  ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24", "10.0.34.0/24", "10.0.35.0/24", "10.0.36.0/24"]
    private_persistence_subnets =  ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

    azs =  "${var.availability_zones}"
    aws_region = "${var.aws_account["default_region"]}"

    # bastion-host variables
    config_bucket_name = "${module.config-bucket.bucket_name}"
    config_bucket_arn = "${module.config-bucket.arn}"
    bastion_host_keypair = "bastion-host-ga"
}

# Output to be accessible by remote state
output "vpc_id" {
  value = "${module.network.vpc_id}"
}

output "vpc_cidr" {
  value = "${module.network.vpc_cidr}"
}

output "private_app_route_table_ids" {
  value = "${module.network.private_app_route_table_ids}"
}