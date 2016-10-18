module "network" {
    source = "github.com/stakater/blueprint-network-aws.git//modules?ref=bastian-ami"

    vpc_cidr = "10.2.0.0/16"
    name = "${var.stack_name}-qa"

    public_subnets = ["10.2.71.0/24", "10.2.72.0/24", "10.2.73.0/24", "10.2.74.0/24", "10.2.75.0/24", "10.2.76.0/24"]
    private_app_subnets =  ["10.2.31.0/24", "10.2.32.0/24", "10.2.33.0/24", "10.2.34.0/24", "10.2.35.0/24", "10.2.36.0/24"]
    private_persistence_subnets =  ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]

    azs =  "${var.availability_zones}"
    aws_region = "${var.aws_account["default_region"]}"

    # bastion-host variables
    config_bucket_name = "${module.config-bucket.bucket_name}"
    config_bucket_arn = "${module.config-bucket.arn}"
    bastion_host_keypair = "bastion-host-qa"
    bastion_host_ami_id  = "${var.bastion_host_ami_id}"

    # variables for peering this vpc with another vpc
    peer_owner_id = "${var.aws_account["id"]}"
    peer_vpc_id  = "${data.terraform_remote_state.global-admiral.vpc_id}"
    peer_vpc_cidr = "${data.terraform_remote_state.global-admiral.vpc_cidr}"
    peer_private_app_route_table_ids = "${data.terraform_remote_state.global-admiral.private_app_route_table_ids}"
}