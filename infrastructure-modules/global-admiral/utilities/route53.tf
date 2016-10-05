module "route53-private" {
  source         = "github.com/stakater/blueprint-utilities-aws.git//modules/route53/private"
  private_domain = "${var.stack_name}.local"
  vpc_id         = "${module.network.vpc_id}"
}

output "route53_private_zone_id" {
  value = "${module.route53-private.zone_id}"
}