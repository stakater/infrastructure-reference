## Provisions basic autoscaling group
module "docker-registry" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool"

  # Resource tags
  name = "${var.stack_name}-ga-registry"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  vpc_cidr  = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_app_subnet_ids}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.small"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.docker-registry-policy.rendered}"
  user_data        = "${data.template_file.docker-registry-bootstrap-user-data.rendered}"
  key_name         = "docker-registry"
  root_vol_size    = 30
  data_ebs_device_name  = "/dev/sdh"  # mount to /opt/data (for registry data)
  data_ebs_vol_size     = 100
  logs_ebs_device_name  = "/dev/sdg"
  logs_ebs_vol_size     = 12

  # ASG parameters
  max_size         = "1"
  min_size         = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.docker-registry-elb.id}"
}

## Template files
data "template_file" "docker-registry-policy" {
  template = "${file("./policy/docker-registry-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
  }
}

data "template_file" "docker-registry-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${module.config-bucket.bucket_name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "docker-registry"
    additional_user_data_scripts = "${file("./scripts/docker-registry-additional-user-data-script.sh")}"
  }
}

data "template_file" "docker-registry-user-data" {
  template = "${file("./user-data/docker-registry.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
  }
}

data "template_file" "docker-registry-upload-script" {
  template = "${file("./data/docker-registry/upload-registry-certs.sh.tmpl")}"

  vars {
    config_bucket_name = "${module.config-bucket.bucket_name}"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "docker_registry_cloud_config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "docker-registry/cloud-config.yaml"
  content = "${data.template_file.docker-registry-user-data.rendered}"
}

##########################
# Upload docker-registry Data to s3
##########################
resource "aws_s3_bucket_object" "docker_registry_upload_script" {
  bucket = "${module.config-bucket.bucket_name}"
  key = "docker-registry/upload-registry-certs.sh"
  content = "${data.template_file.docker-registry-upload-script.rendered}"
}

####################################################

## Creates ELB security group
resource "aws_security_group" "docker-registry-sg-elb" {
  name_prefix = "${var.stack_name}-registry-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-docker-registry-elb"
    managed_by  = "Stakater"
  }

  lifecycle {
    create_before_destroy = true
  }

  # Allow HTTP traffic inside vpc only
  ingress {
    cidr_blocks = ["${module.network.vpc_cidr}"]
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
resource "aws_elb" "docker-registry-elb" {
  name                      = "${var.stack_name}-registry"
  security_groups           = ["${aws_security_group.docker-registry-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.public_subnet_ids)}"]
  internal                  = false
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-registry"
    managed_by  = "Stakater"
  }

  listener {
    instance_port     = 5000
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
resource "aws_lb_cookie_stickiness_policy" "docker-registry-elb-stickiness-policy" {
      name = "${aws_elb.docker-registry-elb.name}-stickiness"
      load_balancer = "${aws_elb.docker-registry-elb.id}"
      lb_port = 80
}

# Route53 record
resource "aws_route53_record" "docker-registry" {
  zone_id = "${module.route53-private.zone_id}"
  name = "registry"
  type = "A"

  alias {
    name = "${aws_elb.docker-registry-elb.dns_name}"
    zone_id = "${aws_elb.docker-registry-elb.zone_id}"
    evaluate_target_health = true
  }
}

## Adds security group rules
resource "aws_security_group_rule" "sg_docker_registry" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.docker-registry.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "docker_registry_scale_up_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-registry-scaleup-policy"

  # ASG parameters
  asg_name = "${module.docker-registry.asg_name}"
  asg_id   = "${module.docker-registry.asg_id}"

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

module "docker_registry_scale_down_policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-ga-registry-scaledown-policy"

  # ASG parameters
  asg_name = "${module.docker-registry.asg_name}"
  asg_id   = "${module.docker-registry.asg_id}"

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


# Outputs to be accessible by remote state
# For allowing other VPCs to interact with docker-registry
output "docker-registry-sg-id" {
  value = "${aws_security_group.docker-registry-sg-elb.id}"
}