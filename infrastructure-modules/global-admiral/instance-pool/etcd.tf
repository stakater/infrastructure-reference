## Provisions basic autoscaling group
module "etcd" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-etcd"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  vpc_cidr  = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.micro"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.etcd-policy.rendered}"
  user_data        = "${data.template_file.bootstrap-user-data.rendered}"
  key_name         = "etcd"
  root_vol_size    = 20
  data_ebs_device_name  = "/dev/sdf"
  data_ebs_vol_size     = 12
  logs_ebs_device_name  = "/dev/sdg"
  logs_ebs_vol_size     = 12

  # ASG parameters
  max_size         = "1"
  min_size         = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.elb.id}"
}

## Template files
data "template_file" "etcd-policy" {
  template = "${file("./policy/etcd-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
  }
}

data "template_file" "bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    config_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "etcd"
    additional_user_data_script = ""
  }
}

data "template_file" "etcd-user-data" {
  template = "${file("./user-data/etcd-user-data.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    s3_bucket_uri = "s3://${module.cloudinit-bucket.bucket_name}"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "etcd_cloud_config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "etcd/cloud-config.yaml"
  content = "${data.template_file.etcd-user-data.rendered}"
}

## Creates ELB security group
resource "aws_security_group" "sg_elb" {
  name_prefix = "${var.stack_name}-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-elb"
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
resource "aws_elb" "elb" {
  security_groups           = ["${aws_security_group.sg_elb.id}"]
  subnets                   = ["${split(",",module.network.public_subnet_ids)}"]
  internal                  = false
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-etcd"
    managed_by  = "Stakater"
  }

  listener {
    instance_port     = 2379
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
resource "aws_lb_cookie_stickiness_policy" "elb_stickiness_policy" {
      name = "${aws_elb.elb.name}-stickiness"
      load_balancer = "${aws_elb.elb.id}"
      lb_port = 80
}

## Adds security group rules
resource "aws_security_group_rule" "sg_etcd" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.etcd.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg_fleet" {
  type                     = "ingress"
  from_port                = 4001
  to_port                  = 4001
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.etcd.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "etcd_scale_up_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-etcd-scaleup-policy"

  # ASG parameters
  asg_name = "${module.etcd.asg_name}"
  asg_id   = "${module.etcd.asg_id}"

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

module "etcd_scale_down_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy?ref=asg-lc"

  # Resource tags
  name = "${var.stack_name}-ga-etcd-scaledown-policy"

  # ASG parameters
  asg_name = "${module.etcd.asg_name}"
  asg_id   = "${module.etcd.asg_id}"

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

# Output to be accessible by remote state
output "etcd_security_group_id" {
  value = "${module.etcd.security_group_id}"
}
