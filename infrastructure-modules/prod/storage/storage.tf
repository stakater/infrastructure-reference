module "config-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.prod_config_bucket_name}"
}

module "cloudinit-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.prod_cloudinit_bucket_name}"
}

# Outputs to be accessible through remote state
output "config-bucket-arn" {
  value = "${module.config-bucket.arn}"
}

output "config-bucket-name" {
  value = "${module.config-bucket.bucket_name}"
}

output "cloudinit-bucket-arn" {
  value = "${module.cloudinit-bucket.arn}"
}