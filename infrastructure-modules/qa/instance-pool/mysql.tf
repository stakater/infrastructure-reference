## Provisions basic autoscaling group
module "mysql" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/instance-pool"

  # Resource tags
  name = "${var.stack_name}-qa-mysql"

  # VPC parameters
  vpc_id  = "${module.network.vpc_id}"
  subnets = "${module.network.private_persistence_subnets}"
  region  = "${var.aws_account["default_region"]}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "t2.micro"
  iam_assume_role_policy = "${file("./policy/assume-role-policy.json")}"
  iam_role_policy  = "${data.template_file.mysql-policy.rendered}"
  user_data        = "${data.template_file.mysql-bootstrap-user-data.rendered}"
  key_name         = "mysql-qa"
  root_vol_size    = 30
  data_ebs_device_name  = "/dev/sdh"
  data_ebs_vol_size     = 150
  logs_ebs_device_name  = "/dev/sdg"
  logs_ebs_vol_size     = 20

  # ASG parameters
  max_size         = "1"
  min_size         = "1"
  min_elb_capacity = "1"
  load_balancers   = "${aws_elb.mysql-elb-internal.id}" # Assign both ELBs to instance-pool module
}

## Template files
data "template_file" "mysql-policy" {
  template = "${file("./policy/mysql-role-policy.json")}"

  vars {
    config_bucket_arn = "${module.config-bucket.arn}"
    cloudinit_bucket_arn = "${module.cloudinit-bucket.arn}"
    global_admiral_config_bucket_arn = "${data.terraform_remote_state.global-admiral.config-bucket-arn}"
  }
}

data "template_file" "mysql-bootstrap-user-data" {
  template = "${file("./user-data/bootstrap-user-data.sh.tmpl")}"

  vars {
    stack_name = "${var.stack_name}"
    config_bucket_name = "${data.terraform_remote_state.global-admiral.config-bucket-name}"
    cloudinit_bucket_name = "${module.cloudinit-bucket.bucket_name}"
    module_name = "mysql"
    additional_user_data_scripts = ""
  }
}

data "template_file" "mysql-user-data" {
  template = "${file("./user-data/mysql.yaml")}"

  vars {
    stack_name = "${var.stack_name}"
    db_username = "${var.qa_database_username}"
    db_password = "${var.qa_database_password}"
    db_name = "${var.qa_database_name}"
  }
}

# Upload CoreOS cloud-config to a s3 bucket; bootstrap-user-data.sh script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "mysql-cloud-config" {
  bucket = "${module.cloudinit-bucket.bucket_name}"
  key = "mysql/cloud-config.yaml"
  content = "${data.template_file.mysql-user-data.rendered}"
}

## Creates ELB security group
resource "aws_security_group" "mysql-sg-elb" {
  name_prefix = "${var.stack_name}-qa-mysql-elb-"
  vpc_id      = "${module.network.vpc_id}"

  tags {
    Name        = "${var.stack_name}-qa-mysql-elb"
    managed_by  = "Stakater"
  }

  lifecycle {
    create_before_destroy = true
  }

  # Allow HTTP traffic
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

## Internal load balancer 
resource "aws_elb" "mysql-elb-internal" {
  name                      = "${var.stack_name}-qa-mysql-int"
  security_groups           = ["${aws_security_group.mysql-sg-elb.id}"]
  subnets                   = ["${split(",",module.network.private_persistence_subnets)}"]
  internal                  = true
  cross_zone_load_balancing = true
  connection_draining       = true

  tags {
    Name        = "${var.stack_name}-qa-mysql-internal"
    managed_by  = "Stakater"
  }

  listener {
    instance_port     = 3306
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
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

# Route53 record
resource "aws_route53_record" "mysql-internal" {
  zone_id = "${module.route53-private.zone_id}"
  name = "mysql-qa"
  type = "A"

  alias {
    name = "${aws_elb.mysql-elb-internal.dns_name}"
    zone_id = "${aws_elb.mysql-elb-internal.zone_id}"
    evaluate_target_health = true
  }
}

####################################
# ASG Scaling Policies
####################################
## Provisions autoscaling policies and associated resources
module "mysql-scale-up-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-qa-mysql-scaleup-policy"

  # ASG parameters
  asg_name = "${module.mysql.asg_name}"
  asg_id   = "${module.mysql.asg_id}"

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

module "mysql-scale-down-policy" {
  source = "git::https://github.com/stakater/blueprint-instance-pool-aws.git//modules/asg-policy"

  # Resource tags
  name = "${var.stack_name}-qa-mysql-scaledown-policy"

  # ASG parameters
  asg_name = "${module.mysql.asg_name}"
  asg_id   = "${module.mysql.asg_id}"

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


##############################
## Security Group Rules
##############################
# Allow ssh from within vpc
resource "aws_security_group_rule" "sg-mysql-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.mysql.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Allow Outgoing traffic
resource "aws_security_group_rule" "sg-mysql-outgoing" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.mysql.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg-mysql-app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  cidr_blocks              = ["${module.network.vpc_cidr}"]
  security_group_id        = "${module.mysql.security_group_id}"

  lifecycle {
    create_before_destroy = true
  }
}