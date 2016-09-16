module "vpc-peering-dev-target" {
    source = "github.com/stakater/blueprint-network-aws.git//modules/vpc-peering/peering-target?ref=vpc-peering"

    target_route_table_ids = "${module.network.private_app_route_table_ids}"
    # workaround: using number of availability_zones for the number of routes to be added in the route table
    # https://github.com/hashicorp/terraform/issues/3888
    target_route_table_ids_count = "${length(var.availability_zones)}"

    vpc_peering_connection_id = "${data.terraform_remote_state.dev_state.vpc_peering_conection_id_ga_dev}"
    root_vpc_cidr = "${data.terraform_remote_state.dev_state.vpc_cidr}"
}

data "terraform_remote_state" "dev_state" {
    backend = "s3"
    config {
        bucket = "${var.tf_state_bucket_name}"
        key = "dev/terraform.tfstate"
        region = "${var.aws_account["default_region"]}"
    }
}