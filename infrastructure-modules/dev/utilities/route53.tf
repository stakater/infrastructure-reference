module "route53-private" {
  source         = "github.com/stakater/blueprint-utilities-aws.git//modules/route53/private"
  private_domain = "${var.stack_name}.local"
  vpc_id         = "${module.network.vpc_id}"
}

output "route53_private_zone_id" {
  value = "${module.route53-private.zone_id}"
}

# Route53 record for registry in this VPC's private dns
resource "aws_route53_record" "docker-registry" {
  zone_id = "${module.route53-private.zone_id}"
  name = "registry"
  type = "A"

  alias {
    name = "${data.terraform_remote_state.global-admiral.registry_elb_dns_name}"
    zone_id = "${data.terraform_remote_state.global-admiral.registry_elb_zone_id}"
    evaluate_target_health = true
  }
}
