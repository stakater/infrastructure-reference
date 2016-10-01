module "efs" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/efs/file-system"
  name = "${var.stack_name}-qa"
  vpc_id = "${module.network.vpc_id}"
  vpc_cidr = "${module.network.vpc_cidr}"
}

module "efs-mount-targets" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/efs/mount-target"
  efs-id = "${module.efs.file-system-id}"
  subnets = "${module.network.private_persistence_subnet_ids}"
  mount-targets-count = "${length(var.availability_zones)}" # Send count for number of mount targets separately https://github.com/hashicorp/terraform/issues/3888
  security-groups = "${module.efs.efs-sg-id}"
}