###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
module "tools-portal" {
  source                      = "git::https://github.com/stakater/blueprint-solo-instance-aws.git//modules?ref=v0.1.0"
  name                        = "${var.stack_name}-prod-tools-portal"
  vpc_id                      = "${module.network.vpc_id}"
  subnet_id                   = "${element(split(",", module.network.public_subnet_ids), 0)}" # First subnet
  iam_assume_role_policy      = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy             = "${data.template_file.tools-portal-policy.rendered}"
  ami                         = "${var.ami}"
  instance_type               = "t2.nano"
  key_name                    = "${var.stack_name}-prod-tools-portal"
  enable_eip                  = true
  associate_public_ip_address = true
  user_data                   = "${data.template_file.tools-portal-bootstrap-user-data.rendered}"
  root_vol_size               = 20
  root_vol_del_on_term        = true
}

## Template files
data "template_file" "tools-portal-policy" {
  template = "${file("./policy/tools-portal-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
    global_admiral_config_bucket_arn = "${data.terraform_remote_state.global-admiral.config-bucket-arn}"
  }
}

data "template_file" "tools-portal-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${data.terraform_remote_state.global-admiral.config-bucket-name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "tools-portal"
    additional_user_data_scripts = ""
  }
}

data "template_file" "tools-portal-user-data" {
  template = "${file("./user-data/tools-portal.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${module.config-bucket.bucket_name}"
    global_admiral_config_bucket="${data.terraform_remote_state.global-admiral.config-bucket-name}"
    module_name="tools-portal"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "tools-portal-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "tools-portal/cloud-config.yaml"
  content = "${data.template_file.tools-portal-user-data.rendered}"
}

# Upload nginx template to s3 bucket
resource "aws_s3_bucket_object" "tools-portal-nginx-config-tmpl" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "tools-portal/nginx/consul-templates/service.ctmpl"
  source = "./data/tools-portal/consul-templates/nginx.ctmpl"
}

# Route53 record
# Add to prod's private dns
resource "aws_route53_record" "tools-portal" {
  zone_id = "${module.route53-private.zone_id}"
  name = "tools-portal-prod"
  type = "A"
  ttl  = "300"
  records = ["${module.tools-portal.public-ip}"]
}

##############################
## Security Group Rules
##############################
# Allow ssh from within vpc
resource "aws_security_group_rule" "sg-tools-portal-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.tools-portal.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Allow Outgoing traffic
resource "aws_security_group_rule" "sg-tools-portal-outgoing" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.tools-portal.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-tools-portal-80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.tools-portal.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-tools-portal-consul" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8301
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.tools-portal.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-tools-portal-consul-8500" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.tools-portal.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs to be accessible through remote state
output "tools-portal-security-group-id" {
  value = "${module.tools-portal.security_group_id}"
}