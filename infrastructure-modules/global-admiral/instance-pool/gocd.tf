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
module "gocd" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool"

  # Resource tags
  name = "${var.stack_name}-ga-gocd"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.large"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.gocd-policy.rendered}"
  user_data        = "${data.template_file.gocd-bootstrap-user-data.rendered}"
  key_name         = "gocd"
  root_vol_size    = 150
  data_ebs_device_name  = ""
  data_ebs_vol_size     = 0
  logs_ebs_device_name  = ""
  logs_ebs_vol_size     = 0

  # ASG parameters
  max_size         = "1"
  min_size         = "1"
  desired_size     = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.gocd-elb.id}"
}

## Template files
data "template_file" "gocd-policy" {
  template = "${file("./policy/gocd-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
    dev_config_bucket_name = "${var.dev_config_bucket_name}"
    qa_config_bucket_name = "${var.qa_config_bucket_name}"
    prod_config_bucket_name = "${var.prod_config_bucket_name}"
    prod_cloudinit_bucket_name = "${var.prod_cloudinit_bucket_name}"
    stage_config_bucket_name = "${var.stage_config_bucket_name}"
    stage_cloudinit_bucket_name = "${var.stage_cloudinit_bucket_name}"
    tf_state_bucket_name = "${var.tf_state_bucket_name}"
  }
}

data "template_file" "gocd-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${module.config-bucket.bucket_name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "gocd"
    additional_user_data_scripts = "${file("./scripts/gocd-additional-user-data-script.sh")}
    ${file("./scripts/download-registry-certificates.sh")}"
  }
}

data "template_file" "gocd-user-data" {
  template = "${file("./user-data/gocd-user-data.yaml")}"

  vars {
  }
}

data "template_file" "gocd-params-tmpl" {
  template = "${file("./data/gocd/scripts/gocd.parameters.txt.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    dev_config_bucket_name = "${var.dev_config_bucket_name}"
    qa_config_bucket_name = "${var.qa_config_bucket_name}"
    stage_config_bucket_name = "${var.stage_config_bucket_name}"
    prod_config_bucket_name = "${var.prod_config_bucket_name}"
  }
}

data "template_file" "gocd-bg-deploy-params-tmpl" {
  template = "${file("./data/gocd/scripts/bg.parameters.txt.tmpl")}"

  vars {
    tf_state_bucket_name = "${var.tf_state_bucket_name}"
    global_admiral_state_key = "${var.tf_state_global_admiral_key}"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "gocd_cloud_config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "gocd/cloud-config.yaml"
  content = "${data.template_file.gocd-user-data.rendered}"
}

##########################
# Upload GoCD Data to s3
##########################
resource "aws_s3_bucket_object" "gocd_build_ami" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/build-ami.sh"
  source = "./data/gocd/scripts/build-ami.sh"
}
resource "aws_s3_bucket_object" "gocd_git_cloner" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/git-cloner.sh"
  source = "./data/gocd/scripts/git-cloner.sh"
}
resource "aws_s3_bucket_object" "clone_deployment_application_code" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/clone-deployment-application-code.sh"
  source = "./data/gocd/scripts/clone-deployment-application-code.sh"
}
resource "aws_s3_bucket_object" "gocd_build_docker_image" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/build-docker-image.sh"
  source = "./data/gocd/scripts/build-docker-image.sh"
}
resource "aws_s3_bucket_object" "gocd_compile_code" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/compile-code.sh"
  source = "./data/gocd/scripts/compile-code.sh"
}
resource "aws_s3_bucket_object" "gocd_delete_ami" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/delete-ami.sh"
  source = "./data/gocd/scripts/delete-ami.sh"
}
resource "aws_s3_bucket_object" "gocd_deploy_to_cluster" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/deploy-to-cluster.sh"
  source = "./data/gocd/scripts/deploy-to-cluster.sh"
}
resource "aws_s3_bucket_object" "gocd_deploy_to_admiral" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/deploy-to-admiral.sh"
  source = "./data/gocd/scripts/deploy-to-admiral.sh"
}
resource "aws_s3_bucket_object" "gocd_deploy_to_admiral_ami" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/deploy-to-admiral-ami.sh"
  source = "./data/gocd/scripts/deploy-to-admiral-ami.sh"
}
resource "aws_s3_bucket_object" "gocd_deploy_to_prod" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/deploy-to-prod.sh"
  source = "./data/gocd/scripts/deploy-to-prod.sh"
}
resource "aws_s3_bucket_object" "gocd_destroy_BG_group" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/destroy-BG-group.sh"
  source = "./data/gocd/scripts/destroy-BG-group.sh"
}
resource "aws_s3_bucket_object" "gocd_docker_cleanup" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/docker-cleanup.sh"
  source = "./data/gocd/scripts/docker-cleanup.sh"
}
resource "aws_s3_bucket_object" "gocd_clean-up" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/clean-up.sh"
  source = "./data/gocd/scripts/clean-up.sh"
}
resource "aws_s3_bucket_object" "gocd_gocd_parameters" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/gocd.parameters.txt"
  content = "${data.template_file.gocd-params-tmpl.rendered}"
}
resource "aws_s3_bucket_object" "gocd_bg_deploy_params" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/bg.parameters.txt"
  content = "${data.template_file.gocd-bg-deploy-params-tmpl.rendered}"
}
resource "aws_s3_bucket_object" "gocd_read_parameter" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/read-parameter.sh"
  source = "./data/gocd/scripts/read-parameter.sh"
}
resource "aws_s3_bucket_object" "gocd_rollback_deployment" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/rollback-deployment.sh"
  source = "./data/gocd/scripts/rollback-deployment.sh"
}
resource "aws_s3_bucket_object" "gocd_switch_deployment_group" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/switch-deployment-group.sh"
  source = "./data/gocd/scripts/switch-deployment-group.sh"
}
resource "aws_s3_bucket_object" "gocd_terraform_apply_changes" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/terraform-apply-changes.sh"
  source = "./data/gocd/scripts/terraform-apply-changes.sh"
}
resource "aws_s3_bucket_object" "gocd_test" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/test-code.sh"
  source = "./data/gocd/scripts/test-code.sh"
}
resource "aws_s3_bucket_object" "gocd_update_blue_green_deployment_groups" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/update-blue-green-deployment-groups.sh"
  source = "./data/gocd/scripts/update-blue-green-deployment-groups.sh"
}
resource "aws_s3_bucket_object" "gocd_update_deployment_state" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/update-deployment-state.sh"
  source = "./data/gocd/scripts/update-deployment-state.sh"
}
resource "aws_s3_bucket_object" "gocd_write_ami_parameters" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/write-ami-parameters.sh"
  source = "./data/gocd/scripts/write-ami-parameters.sh"
}
resource "aws_s3_bucket_object" "gocd_write_terraform_variables" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/write-terraform-variables.sh"
  source = "./data/gocd/scripts/write-terraform-variables.sh"
}
resource "aws_s3_bucket_object" "sort-and-combine-script" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/sort-and-combine-comma-separated-list.sh"
  source = "./data/gocd/scripts/sort-and-combine-comma-separated-list.sh"
}
resource "aws_s3_bucket_object" "gocd_resume_ASG_processes" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/resume-ASG-processes.sh"
  source = "./data/gocd/scripts/resume-ASG-processes.sh"
}
resource "aws_s3_bucket_object" "gocd_start_infra" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/start-infra.sh"
  source = "./data/gocd/scripts/start-infra.sh"
}
resource "aws_s3_bucket_object" "gocd_start_instances" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/start-instances.sh"
  source = "./data/gocd/scripts/start-instances.sh"
}
resource "aws_s3_bucket_object" "gocd_stop_infra" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/stop-infra.sh"
  source = "./data/gocd/scripts/stop-infra.sh"
}
resource "aws_s3_bucket_object" "gocd_stop_instances" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/stop-instances.sh"
  source = "./data/gocd/scripts/stop-instances.sh"
}
resource "aws_s3_bucket_object" "gocd_suspend_ASG_processes" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/suspend-ASG-processes.sh"
  source = "./data/gocd/scripts/suspend-ASG-processes.sh"
}
resource "aws_s3_bucket_object" "gocd_cruise_config" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/conf/cruise-config.xml"
  source = "./data/gocd/conf/cruise-config.xml"
}
resource "aws_s3_bucket_object" "gocd_passwd" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/conf/passwd"
  source = "./data/gocd/conf/passwd"
}
resource "aws_s3_bucket_object" "gocd_sudoers" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/conf/sudoers"
  source = "./data/gocd/conf/sudoers"
}
####################################################

## Creates ELB security group
resource "aws_security_group" "gocd-sg-elb" {
  name_prefix = "${var.stack_name}-gocd-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-gocd-elb"
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

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

## Creates ELB
resource "aws_elb" "gocd-elb" {
  name                      = "${var.stack_name}-gocd"
  security_groups           = ["${aws_security_group.gocd-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.public_subnet_ids)}"]
  internal                  = false
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-gocd"
    managed_by  = "Stakater"
  }

  listener {
    instance_port     = 8153
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

# ELB Stickiness policy
resource "aws_lb_cookie_stickiness_policy" "gocd-elb-stickiness-policy" {
      name = "${aws_elb.gocd-elb.name}-stickiness"
      load_balancer = "${aws_elb.gocd-elb.id}"
      lb_port = 80
}

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "gocd_scale_up_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-gocd-scaleup-policy"

  # ASG parameters
  asg_name = "${module.gocd.asg_name}"
  asg_id   = "${module.gocd.asg_id}"

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

module "gocd_scale_down_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-gocd-scaledown-policy"

  # ASG parameters
  asg_name = "${module.gocd.asg_name}"
  asg_id   = "${module.gocd.asg_id}"

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
resource "aws_security_group_rule" "sg-gocd-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.gocd.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Allow Outgoing traffic
resource "aws_security_group_rule" "sg-gocd-outgoing" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.gocd.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-gocd-app" {
  type                     = "ingress"
  from_port                = 8153
  to_port                  = 8153
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.gocd.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}
