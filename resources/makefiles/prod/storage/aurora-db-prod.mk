# Separate from storage because needs to made after network
aurora_db_prod: plan_aurora_db_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY)	-target module.aurora-db \
							-target aws_route53_record.aurora-db-record;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_aurora_db_prod: init_aurora_db_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target module.aurora-db \
						 -target aws_route53_record.aurora-db-record;

refresh_aurora_db_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.aurora-db \
								-target aws_route53_record.aurora-db-record;

destroy_aurora_db_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_DESTROY) -target aws_route53_record.aurora-db-record \
								-target module.aurora-db;

clean_aurora_db_prod: destroy_aurora_db_prod
	rm -f $(BUILD_PROD)/aurora-db.tf

init_aurora_db_prod: init_prod
		cp -rf $(INFRA_PROD)/storage/aurora-db.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: aurora_db_prod destroy_aurora_db_prod refresh_aurora_db_prod plan_aurora_db_prod init_aurora_db_prod clean_aurora_db_prod