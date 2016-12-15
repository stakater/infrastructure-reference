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
