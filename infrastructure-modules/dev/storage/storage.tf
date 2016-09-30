module "config-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-dev-config"
}

module "cloudinit-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-dev-cloudinit"
}