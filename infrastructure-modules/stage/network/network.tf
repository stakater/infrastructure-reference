module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules"

    vpc_cidr = "10.4.0.0/16"
    name = "${var.stack_name}-stage"

    public_subnets = ["10.4.71.0/24", "10.4.72.0/24", "10.4.73.0/24", "10.4.74.0/24", "10.4.75.0/24", "10.4.76.0/24"]
    private_app_subnets =  ["10.4.31.0/24", "10.4.32.0/24", "10.4.33.0/24", "10.4.34.0/24", "10.4.35.0/24", "10.4.36.0/24"]
    private_persistence_subnets =  ["10.4.1.0/24", "10.4.2.0/24", "10.4.3.0/24", "10.4.4.0/24", "10.4.5.0/24", "10.4.6.0/24"]

    azs =  "${var.availability_zones}"
    aws_region = "${var.aws_account["default_region"]}"

    # bastion-host variables
    config_bucket_name = "${module.config-bucket.bucket_name}"
    config_bucket_arn = "${module.config-bucket.arn}"
    bastion_host_keypair = "bastion-host-stage"
    bastion_host_ami_id  = "${var.bastion_host_ami_id}"

    # variables for peering this vpc with another vpc
    peer_owner_id = "${var.aws_account["id"]}"
    peer_vpc_id  = "${data.terraform_remote_state.global-admiral.vpc_id}"
    peer_vpc_cidr = "${data.terraform_remote_state.global-admiral.vpc_cidr}"
    peer_private_app_route_table_ids = "${data.terraform_remote_state.global-admiral.private_app_route_table_ids}"
}

# Output to be accessible through remote state
output "vpc_id" {
  value = "${module.network.vpc_id}"
}

output "vpc_cidr" {
  value = "${module.network.vpc_cidr}"
}

output "private_app_subnet_ids" {
  value = "${module.network.private_app_subnet_ids}"
}

output "public_subnet_ids" {
  value = "${module.network.public_subnet_ids}"
}