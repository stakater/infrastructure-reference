module "config-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.prod_config_bucket_name}"
}

module "cloudinit-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.prod_cloudinit_bucket_name}"
}

module "maintenance-page-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3-static-website-hosting?ref=static-website-hosting"
  name = "${var.stack_name}-maintenance-page}"
  policy = "${data.template_file.static-website-hosting-policy.rendered}"
  index = "index.html"
  error = "error.html"
}

##########################
# Upload Index file to s3
##########################
resource "aws_s3_bucket_object" "upload-maintenance-index-page" {
  bucket = "${module.maintenance-page-bucket.bucket_name}"
  key = "index.html"
  content = "${file("./data/index.html")}"
}
resource "aws_s3_bucket_object" "upload-maintenance-error-page" {
  bucket = "${module.maintenance-page-bucket.bucket_name}"
  key = "error.html"
  content = "${file("./data/error.html")}"
}


## Template files
data "template_file" "static-website-hosting-policy" {
  template = "${file("./policy/static-website-hosting-policy.json")}"
  vars {
    bucket_name = "${var.stack_name}-maintenance-page}"
  }
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

output "maintenance-page-bucket-arn" {
  value = "${module.maintenance-page-bucket.arn}"
}

output "maintenance-page-bucket-name" {
  value = "${module.maintenance-page-bucket.bucket_name}"
}

output "maintenance-page-bucket-website-endpoint" {
  value = "${module.maintenance-page-bucket.endpoint}"
}
