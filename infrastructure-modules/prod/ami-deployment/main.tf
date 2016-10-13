# AMI Deployment

## Configures providers
provider "aws" {
  region = "${var.region}"
}

## Creates IAM role
resource "aws_iam_role" "role" {
  name = "${var.stack_item_label}-${var.region}"
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name  = "${var.stack_item_label}-${var.region}"
  roles = ["${aws_iam_role.role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "policy_monitoring" {
  name = "monitoring"
  role = "${aws_iam_role.role.id}"

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

## Creates ELB security group
resource "aws_security_group" "sg_elb" {
  name_prefix = "${var.stack_item_label}-elb-"
  description = "Standard ASG example ELB"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name        = "${var.stack_item_label}-elb"
    application = "${var.stack_item_fullname}"
    managed_by  = "terraform"
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
  subnets                   = ["${split(",",var.subnet_ids)}"] 
  internal                  = "${var.internal}"
  cross_zone_load_balancing = "${var.cross_zone_lb}"
  connection_draining       = "${var.connection_draining}"

  tags {
    Name        = "${var.stack_item_label}"
    application = "${var.stack_item_fullname}"
    managed_by  = "terraform"
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

## Adds security group rules
resource "aws_security_group_rule" "sg_asg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${module.deploy_ami.sg_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg_asg_elb" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.sg_elb.id}"
  security_group_id        = "${module.deploy_ami.sg_id}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group_rule" "sg_asg_elb_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${module.deploy_ami.sg_id}"

  lifecycle {
    create_before_destroy = true
  }
}

## Generates instance user data from a template
resource "template_file" "user_data" {
  template = "${file("../templates/user_data.tpl")}"

  vars {
    hostname = "${var.stack_item_label}"
    domain   = "deployment.org"
    region   = "${var.region}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Provisions basic autoscaling group
module "deploy_ami" {
  source = "git::https://github.com/stakater/blueprint-cd.git?ref=automated-deployment//group"  
  
  # Resource tags
  stack_item_label    = "${var.stack_item_label}"
  stack_item_fullname = "${var.stack_item_fullname}"

  # VPC parameters
  vpc_id  = "${var.vpc_id}"
  subnets = "${var.subnet_ids}" 
  region  = "${var.region}"

  # LC parameters
  ami              = "${var.ami}"
  instance_type    = "${var.instance_type}"
  instance_profile = "${aws_iam_instance_profile.instance_profile.id}"
  user_data        = "${template_file.user_data.rendered}"
  key_name         = "${var.key_name}"

  # ASG parameters
  max_size         = "${var.cluster_max_size}"
  min_size         = "${var.cluster_min_size}"
  min_elb_capacity = "${var.min_elb_capacity}"
  load_balancers   = "${aws_elb.elb.id}"
}

## Provisions autoscaling policies and associated resources
module "scale_up_policy" {
  source = "git::https://github.com/stakater/blueprint-cd.git?ref=automated-deployment//policy"

  # Resource tags
  stack_item_label    = "${var.stack_item_label}-up"
  stack_item_fullname = "${var.stack_item_fullname}"

  # ASG parameters
  asg_name = "${module.deploy_ami.asg_name}"

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

module "scale_down_policy" {
  source = "git::https://github.com/stakater/blueprint-cd.git?ref=automated-deployment//policy"

  # Resource tags
  stack_item_label    = "${var.stack_item_label}-down"
  stack_item_fullname = "${var.stack_item_fullname}"

  # ASG parameters
  asg_name = "${module.deploy_ami.asg_name}"

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