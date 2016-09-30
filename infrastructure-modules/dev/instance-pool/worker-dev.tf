## Provisions basic autoscaling group
module "worker-dev" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool"

  # Resource tags
  name = "${var.stack_name}-worker-dev"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  vpc_cidr  = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.medium"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.worker-dev-policy.rendered}"
  user_data        = "${data.template_file.worker-dev-bootstrap-user-data.rendered}"
  key_name         = "worker-dev"
  root_vol_size    = 30
  data_ebs_device_name  = "/dev/sdf"
  data_ebs_vol_size     = 50
  logs_ebs_device_name  = "/dev/sdg"
  logs_ebs_vol_size     = 20

  # ASG parameters
  max_size         = "2"
  min_size         = "2"
  min_elb_capacity = "2"
  load_balancers   = "${aws_elb.worker-dev-elb.id}"
}

## Template files
data "template_file" "worker-dev-policy" {
  template = "${file("./policy/worker-dev-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
    global_admiral_config_bucket_arn = "${data.terraform_remote_state.global-admiral.config-bucket-arn}"
  }
}

data "template_file" "worker-dev-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${data.terraform_remote_state.global-admiral.config-bucket-name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "worker-dev"
    additional_user_data_scripts = "${file("./scripts/download-registry-certificates.sh")}"
  }
}

data "template_file" "worker-dev-user-data" {
  template = "${file("./user-data/worker-dev.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    efs_dns = "${replace(element(split(",", module.efs-mount-targets.dns-names), 0), "/^(.+?)\\./", "")}"
    # Using first value in the comma-separated list and remove the availability zone
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "worker-dev-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "worker-dev/cloud-config.yaml"
  content = "${data.template_file.worker-dev-user-data.rendered}"
}

## Creates ELB security group
resource "aws_security_group" "worker-dev-sg-elb" {
  name_prefix = "${var.stack_name}-worker-dev-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-worker-dev-elb"
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
resource "aws_elb" "worker-dev-elb" {
  name                      = "${var.stack_name}-worker-dev"
  security_groups           = ["${aws_security_group.worker-dev-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.public_subnet_ids)}"]
  internal                  = false
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-worker-dev"
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

# ELB Stickiness policy
resource "aws_lb_cookie_stickiness_policy" "worker-dev-elb-stickiness-policy" {
      name = "${aws_elb.worker-dev-elb.name}-stickiness"
      load_balancer = "${aws_elb.worker-dev-elb.id}"
      lb_port = 80
}

# Route53 record
resource "aws_route53_record" "worker-dev" {
  zone_id = "${data.terraform_remote_state.global-admiral.route53_private_zone_id}"
  name = "registry"
  type = "A"

  alias {
    name = "${aws_elb.worker-dev-elb.dns_name}"
    zone_id = "${aws_elb.worker-dev-elb.zone_id}"
    evaluate_target_health = true
  }
}


####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "worker-dev-scale-up-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-worker-dev-scaleup-policy"

  # ASG parameters
  asg_name = "${module.worker-dev.asg_name}"
  asg_id   = "${module.worker-dev.asg_id}"

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

module "worker-dev-scale-down-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-worker-dev-scaledown-policy"

  # ASG parameters
  asg_name = "${module.worker-dev.asg_name}"
  asg_id   = "${module.worker-dev.asg_id}"

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


## Adds security group rules
resource "aws_security_group_rule" "sg-worker-dev" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8081
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.worker-dev.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Allow fleet to be accessed by modules from global-admiral (e.g. gocd)
resource "aws_security_group_rule" "sg-worker-dev-fleet" {
  type                     = "ingress"
  from_port                = 4001
  to_port                  = 4001
  protocol                 = "tcp"
  cidr_blocks              = ["${data.terraform_remote_state.global-admiral.vpc_cidr}"]
  security_group_id        = "${module.worker-dev.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Adds security group rule in docker registry
# Allow registry to be accessed by this VPC
resource "aws_security_group_rule" "sg_worker_dev_registry" {
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
resource "aws_security_group_rule" "sg_worker_dev_etcd" {
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
