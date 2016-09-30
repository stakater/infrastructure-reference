data "terraform_remote_state" "global-admiral" {
    backend = "s3"
    config {
        bucket = "${var.tf_state_bucket_name}"
        key = "global-admiral/terraform.tfstate"
        region = "${var.aws_account["default_region"]}"
    }
}