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

## Provisions basic autoscaling group
module "worker" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool"

  # Resource tags
  name = "${var.stack_name}-dev-worker"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.nano"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.worker-policy.rendered}"
  user_data        = "${data.template_file.worker-bootstrap-user-data.rendered}"
  key_name         = "worker-dev"
  root_vol_size    = 50
  # Leave empty & 0 if you do not wish to
  # attach EBS to instances of this module
  root_vol_del_on_term = true
  data_ebs_device_name  = ""
  data_ebs_vol_size     = 0
  logs_ebs_device_name  = ""
  logs_ebs_vol_size     = 0

  # ASG parameters
  max_size         = "2"
  min_size         = "1"
  desired_size     = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.worker-elb.id},${aws_elb.worker-elb-internal.id}" # Assign both ELBs to instance-pool module
}

## Template files
data "template_file" "worker-policy" {
  template = "${file("./policy/worker-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
    global_admiral_config_bucket_arn = "${data.terraform_remote_state.global-admiral.config-bucket-arn}"
  }
}

data "template_file" "worker-filebeat-additional-user-data" {
  template = "${file("./scripts/download-filebeat-template.sh.tmpl")}"

  vars {
    dev_config_bucket="${module.config-bucket.bucket_name}"
  }
}

data "template_file" "worker-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${data.terraform_remote_state.global-admiral.config-bucket-name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "worker"
    additional_user_data_scripts = "${file("./scripts/download-registry-certificates.sh")}
    ${data.template_file.worker-filebeat-additional-user-data.rendered}"
  }
}

data "template_file" "worker-user-data" {
  template = "${file("./user-data/worker.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    efs_dns = "${replace(element(split(",", module.efs-mount-targets.dns-names), 0), "/^(.+?)\\./", "")}"
    # Using first value in the comma-separated list and remove the availability zone
    global_admiral_config_bucket="${data.terraform_remote_state.global-admiral.config-bucket-name}"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "worker-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "worker/cloud-config.yaml"
  content = "${data.template_file.worker-user-data.rendered}"
}

# Upload filebeat template to s3 bucket
resource "aws_s3_bucket_object" "filebeat-config-tmpl" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "worker/consul-templates/filebeat.ctmpl"
  source = "./data/worker/consul-templates/filebeat.ctmpl"
}
## Creates ELB security group
resource "aws_security_group" "worker-sg-elb" {
  name_prefix = "${var.stack_name}-dev-worker-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-dev-worker-elb"
    managed_by  = "Stakater"
  }

  lifecycle {
    create_before_destroy = true
  }

  # Allow HTTP traffic
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  # Allow fleet to be accessed by global-admiral VPC modules (e.g. gocd)
  ingress {
    cidr_blocks = ["${data.terraform_remote_state.global-admiral.vpc_cidr}"]
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

## Creates ELB
resource "aws_elb" "worker-elb" {
  name                      = "${var.stack_name}-dev-worker"
  security_groups           = ["${aws_security_group.worker-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.public_subnet_ids)}"]
  internal                  = false
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-dev-worker"
    managed_by  = "Stakater"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:22"
    interval            = 30
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Internal load balancer in private app subnets instead of public subnets
# So that fleet can be accessed through peered vpc i.e. global-admiral
# (As peering is at private-app level and not at public level)
resource "aws_elb" "worker-elb-internal" {
  name                      = "${var.stack_name}-dev-wrkr-int"
  security_groups           = ["${aws_security_group.worker-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.private_app_subnet_ids)}"]
  internal                  = true
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-dev-worker-internal"
    managed_by  = "Stakater"
  }

  # Fleet
  listener {
    instance_port     = 4001
    instance_protocol = "http"
    lb_port           = 4001
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:22"
    interval            = 30
  }

  lifecycle {
    create_before_destroy = true
  }
}
# ELB Stickiness policy
resource "aws_lb_cookie_stickiness_policy" "worker-elb-stickiness-policy" {
      name = "${aws_elb.worker-elb.name}-stickiness"
      load_balancer = "${aws_elb.worker-elb.id}"
      lb_port = 80
}

# Route53 record
# Add to dev's private dns
resource "aws_route53_record" "worker" {
  zone_id = "${module.route53-private.zone_id}"
  name = "worker-dev"
  type = "A"

  alias {
    name = "${aws_elb.worker-elb.dns_name}"
    zone_id = "${aws_elb.worker-elb.zone_id}"
    evaluate_target_health = true
  }
}

# Add to global-admiral's private dns
resource "aws_route53_record" "worker-internal" {
  zone_id = "${data.terraform_remote_state.global-admiral.route53_private_zone_id}"
  name = "worker-dev-fleet"
  type = "A"

  alias {
    name = "${aws_elb.worker-elb-internal.dns_name}"
    zone_id = "${aws_elb.worker-elb-internal.zone_id}"
    evaluate_target_health = true
  }
}

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "worker-scale-up-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-dev-worker-scaleup-policy"

  # ASG parameters
  asg_name = "${module.worker.asg_name}"
  asg_id   = "${module.worker.asg_id}"

  # Notification parameters
  notifications = "autoscaling:EC2_INSTANCE_LAUNCH_ERROR,autoscaling:EC2_INSTANCE_TERMINATE_ERROR"

  # Monitor parameters
  adjustment_type          = "ChangeInCapacity"
  scaling_adjustment       = 1
  cooldown                 = 300
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  evaluation_periods       = 2
  metric_name              = "CPUUtilization"
  period                   = 60
  threshold                = 80
}

module "worker-scale-down-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-dev-worker-scaledown-policy"

  # ASG parameters
  asg_name = "${module.worker.asg_name}"
  asg_id   = "${module.worker.asg_id}"

  # Notification parameters
  notifications = "autoscaling:EC2_INSTANCE_LAUNCH_ERROR,autoscaling:EC2_INSTANCE_TERMINATE_ERROR"

  # Monitor parameters
  adjustment_type     = "ChangeInCapacity"
  scaling_adjustment  = -1
  cooldown            = 300
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 30
  metric_name         = "CPUUtilization"
  period              = 60
  threshold           = 50
}


##############################
## Security Group Rules
##############################
# Allow ssh from within vpc
resource "aws_security_group_rule" "sg-worker-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.worker.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Allow Outgoing traffic
resource "aws_security_group_rule" "sg-worker-outgoing" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.worker.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-worker-app" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8081
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.worker.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Allow fleet to be accessed by load balancer
resource "aws_security_group_rule" "sg-worker-fleet" {
  type                     = "ingress"
  from_port                = 4001
  to_port                  = 4001
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.worker.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Adds security group rule in docker registry
# Allow registry to be accessed by this VPC
resource "aws_security_group_rule" "sg-worker-registry" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${data.terraform_remote_state.global-admiral.docker-registry-sg-id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Allow access to etcd
resource "aws_security_group_rule" "sg-worker-etcd" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${data.terraform_remote_state.global-admiral.etcd-security-group-id}"

  lifecycle {
    create_before_destroy = true
  }
}