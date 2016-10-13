## This tf renders the prod cloud config and uploads it to S3 bucket
## So that it can be downloaded on GoCD and processed by ami-baker module
## And can then used as the base cloud config for the AMI to be created.
## https://github.com/stakater/ami-baker

data "template_file" "prod-user-data" {
  template = "${file("./user-data/prod.tmpl.yaml")}" #path relative to build dir

  vars {
    stack_name = "${var.stack_name}"
    efs_dns = "${replace(element(split(",", module.efs-mount-targets.dns-names), 0), "/^(.+?)\\./", "")}"
    # Using first value in the comma-separated list and remove the availability zone
  }
}

resource "aws_s3_bucket_object" "prod-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "prod/cloud-config.tmpl.yaml"
  content = "${data.template_file.prod-user-data.rendered}"
}