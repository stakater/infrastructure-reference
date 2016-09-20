# Output Variables

output "sg_id" {
  value = "${module.deploy_ami.sg_id}"
}

output "lc_id" {
  value = "${module.deploy_ami.lc_id}"
}

output "asg_id" {
  value = "${module.deploy_ami.asg_id}"
}

output "asg_name" {
  value = "${module.deploy_ami.asg_name}"
}

