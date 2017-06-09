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

module "aurora-db" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/rds/aurora-db?ref=v0.1.0"

  name = "${var.stack_name}-prod"
  vpc_id = "${module.network.vpc_id}"
  vpc_cidr = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_persistence_subnet_ids}"

  aurora_db_name = "${var.prod_database_name}"
  aurora_db_username = "${var.prod_database_username}"
  aurora_db_password = "${var.prod_database_password}"

  # DB Backup
  backup_retention_period = 14
  preferred_backup_window = "02:00-03:00"
  preferred_maintenance_window = "wed:03:00-wed:04:00"

  cluster_instance_count = "1"
  cluster_instance_class = "db.r3.large"
  publicly_accessible = false
}

########################
## Route53 Record
########################
resource "aws_route53_record" "aurora-db-record" {
    zone_id = "${module.route53-private.zone_id}"
    name = "aurora-db-prod"
    type = "CNAME"
    ttl = 60
    records = [ "${module.aurora-db.endpoint}" ]
}

# Outputs to be accessible by remote state
output "aurora-db-endpoint" {
  value = "${module.aurora-db.endpoint}"
}