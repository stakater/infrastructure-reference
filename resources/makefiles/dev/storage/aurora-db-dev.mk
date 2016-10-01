# Separate from storage because needs to made after network
aurora_db_dev: plan_aurora_db_dev
	cd $(BUILD_DEV); \
	$(TF_APPLY)	-target module.aurora-db \
							-target aws_route53_record.aurora-db-record;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_aurora_db_dev: init_aurora_db_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.aurora-db \
						 -target aws_route53_record.aurora-db-record;

refresh_aurora_db_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target module.aurora-db \
								-target aws_route53_record.aurora-db-record;

destroy_aurora_db_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_DESTROY) -target aws_route53_record.aurora-db-record \
								-target module.aurora-db;

clean_aurora_db_dev: destroy_aurora_db_dev
	rm -f $(BUILD_DEV)/aurora-db.tf

init_aurora_db_dev: init_dev
		cp -rf $(INFRA_DEV)/storage/aurora-db.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: aurora_db_dev destroy_aurora_db_dev refresh_aurora_db_dev plan_aurora_db_dev init_aurora_db_dev clean_aurora_db_dev