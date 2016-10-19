module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules"

    vpc_cidr = "10.1.0.0/16"
    name = "${var.stack_name}-dev"

    public_subnets = ["10.1.71.0/24", "10.1.72.0/24", "10.1.73.0/24", "10.1.74.0/24", "10.1.75.0/24", "10.1.76.0/24"]
    private_app_subnets =  ["10.1.31.0/24", "10.1.32.0/24", "10.1.33.0/24", "10.1.34.0/24", "10.1.35.0/24", "10.1.36.0/24"]
    private_persistence_subnets =  ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24", "10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]

    azs =  "${var.availability_zones}"
    aws_region = "${var.aws_account["default_region"]}"

    # bastion-host variables
    config_bucket_name = "${module.config-bucket.bucket_name}"
    config_bucket_arn = "${module.config-bucket.arn}"
    bastion_host_keypair = "bastion-host-dev"
    bastion_host_ami_id  = "${var.bastion_host_ami_id}"

    # variables for peering this vpc with another vpc
    peer_owner_id = "${var.aws_account["id"]}"
    peer_vpc_id  = "${data.terraform_remote_state.global-admiral.vpc_id}"
    peer_vpc_cidr = "${data.terraform_remote_state.global-admiral.vpc_cidr}"
    peer_private_app_route_table_ids = "${data.terraform_remote_state.global-admiral.private_app_route_table_ids}"
}