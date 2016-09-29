## Provisions basic autoscaling group
module "gocd" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-gocd"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  vpc_cidr  = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.large"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.gocd-policy.rendered}"
  user_data        = "${data.template_file.gocd-bootstrap-user-data.rendered}"
  key_name         = "gocd"
  root_vol_size    = 50
  data_ebs_device_name  = "/dev/sdf"
  data_ebs_vol_size     = 100
  logs_ebs_device_name  = "/dev/sdg"
  logs_ebs_vol_size     = 20

  # ASG parameters
  max_size         = "1"
  min_size         = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.gocd-elb.id}"
}

## Template files
data "template_file" "gocd-policy" {
  template = "${file("./policy/gocd-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
  }
}

data "template_file" "gocd-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    config_bucket_name = "${module.config-bucket.bucket_name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "gocd"
    additional_user_data_script = "${file("./scripts/gocd-additional-user-data-script.sh")}"
  }
}

data "template_file" "gocd-user-data" {
  template = "${file("./user-data/gocd-user-data.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    s3_bucket_uri = "s3://${module.cloudinit-bucket.bucket_name}"
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
resource "aws_s3_bucket_object" "gocd_deploy_to_cluster" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/deploy-to-cluster.sh"
  source = "./data/gocd/scripts/deploy-to-cluster.sh"
}
resource "aws_s3_bucket_object" "gocd_docker_cleanup" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/docker-cleanup.sh"
  source = "./data/gocd/scripts/docker-cleanup.sh"
}
resource "aws_s3_bucket_object" "gocd_gocd_parameters" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/gocd.parameters.txt"
  source = "./data/gocd/scripts/gocd.parameters.txt"
}
resource "aws_s3_bucket_object" "gocd_launch_ami" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/launch-ami.sh"
  source = "./data/gocd/scripts/launch-ami.sh"
}
resource "aws_s3_bucket_object" "gocd_read_parameter" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/read-parameters.sh"
  source = "./data/gocd/scripts/read-parameter.sh"
}
resource "aws_s3_bucket_object" "gocd_test" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "gocd/scripts/test-code.sh"
  source = "./data/gocd/scripts/test-code.sh"
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

## Adds security group rules
resource "aws_security_group_rule" "sg_gocd" {
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

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "gocd_scale_up_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-gocd-scaleup-policy"

  # ASG parameters
  asg_name = "${module.gocd.asg_name}"
  asg_id   = "${module.gocd.asg_id}"

  # Notification parameters
  notifications = "autoscaling:EC2_INSTANCE_LAUNCH_ERROR,autoscaling:EC2_INSTANCE_TERMINATE_ERROR"

  # Monitor parameters
  adjustment_type          = "PercentChangeInCapacity"
  scaling_adjustment       = 30
  cooldown                 = 300
  min_adjustment_magnitude = 2
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  evaluation_periods       = 2
  metric_name              = "CPUUtilization"
  period                   = 120
  threshold                = 10
}

module "gocd_scale_down_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-gocd-scaledown-policy"

  # ASG parameters
  asg_name = "${module.gocd.asg_name}"
  asg_id   = "${module.gocd.asg_id}"

  # Notification parameters
  notifications = "autoscaling:EC2_INSTANCE_LAUNCH_ERROR,autoscaling:EC2_INSTANCE_TERMINATE_ERROR"

  # Monitor parameters
  adjustment_type     = "ChangeInCapacity"
  scaling_adjustment  = 2
  cooldown            = 300
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  period              = 120
  threshold           = 10
}