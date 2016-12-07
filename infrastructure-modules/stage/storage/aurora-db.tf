module "aurora-db" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/rds/aurora-db"

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