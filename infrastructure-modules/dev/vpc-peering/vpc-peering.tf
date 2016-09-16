module "vpc-peering-ga-root" {
    source = "github.com/stakater/blueprint-network-aws.git//modules/vpc-peering/peering-root?ref=vpc-peering"
    name = "dev-to-global-admiral"

    root_vpc_id = "${module.network.vpc_id}"
    root_route_table_ids="${module.network.private_app_route_table_ids}"
    # workaround: using number of availability_zones for the number of routes to be added in the route table
    # https://github.com/hashicorp/terraform/issues/3888
    root_route_table_ids_count = "${length(var.availability_zones)}"

    target_owner_id = "${var.aws_account["id"]}" #remote state?
    target_vpc_id = "${data.terraform_remote_state.global_admiral_state.vpc_id}"
    target_vpc_cidr = "${data.terraform_remote_state.global_admiral_state.vpc_cidr}"
}

output "vpc_peering_conection_id_ga_dev" {
  value = "${module.vpc-peering-ga-root.vpc_peering_conection_id}"
}

data "terraform_remote_state" "global_admiral_state" {
    backend = "s3"
    config {
        bucket = "${var.tf_state_bucket_name}"
        key = "global-admiral/terraform.tfstate"
        region = "${var.aws_account["default_region"]}"
    }
}