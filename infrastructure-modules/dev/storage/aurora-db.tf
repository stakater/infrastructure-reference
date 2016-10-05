module "aurora-db" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/rds/aurora-db"

  name = "${var.stack_name}-dev"
  vpc_id = "${module.network.vpc_id}"
  vpc_cidr = "${module.network.vpc_cidr}"
  subnets = "${module.network.private_persistence_subnet_ids}"

  aurora_db_name = "testdb"
  aurora_db_username = "root"
  aurora_db_password = "root12345"

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
    zone_id = "${data.terraform_remote_state.global-admiral.route53_private_zone_id}"
    name = "aurora-db-dev"
    type = "CNAME"
    ttl = 60
    records = [ "${module.aurora-db.endpoint}" ]
}

# Outputs to be accessible by remote state
output "aurora-db-endpoint" {
  value = "${module.aurora-db.endpoint}"
}