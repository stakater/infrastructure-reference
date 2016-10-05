module "config-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-global-admiral-config"
}

module "cloudinit-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-global-admiral-cloudinit"
}

# Outputs to be accessible through remote state
output "config-bucket-arn" {
  value = "${module.config-bucket.arn}"
}

output "config-bucket-name" {
  value = "${module.config-bucket.bucket_name}"
}