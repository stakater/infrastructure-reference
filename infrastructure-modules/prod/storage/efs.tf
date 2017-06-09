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

module "efs" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/efs/file-system?ref=v0.1.0"
  name = "${var.stack_name}-prod"
  vpc_id = "${module.network.vpc_id}"
  vpc_cidr = "${module.network.vpc_cidr}"
}

module "efs-mount-targets" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/efs/mount-target?ref=v0.1.0"
  efs-id = "${module.efs.file-system-id}"
  subnets = "${module.network.private_persistence_subnet_ids}"
  mount-targets-count = "${length(var.availability_zones)}" # Send count for number of mount targets separately https://github.com/hashicorp/terraform/issues/3888
  security-groups = "${module.efs.efs-sg-id}"
}

# Outputs to be accessible by remote state
output "efs-mount-target-dns-names" {
  value = "${module.efs-mount-targets.dns-names}"
}