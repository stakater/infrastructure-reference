# Separate from storage because needs to made after network
aurora_db_qa: plan_aurora_db_qa
	cd $(BUILD_QA); \
	$(TF_APPLY)	-target module.aurora-db \
							-target aws_route53_record.aurora-db-record;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_aurora_db_qa: init_aurora_db_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target module.aurora-db \
						 -target aws_route53_record.aurora-db-record;

refresh_aurora_db_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target module.aurora-db \
								-target aws_route53_record.aurora-db-record;

destroy_aurora_db_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_DESTROY) -target aws_route53_record.aurora-db-record \
								-target module.aurora-db;

clean_aurora_db_qa: destroy_aurora_db_qa
	rm -f $(BUILD_QA)/aurora-db.tf

init_aurora_db_qa: init_qa
		cp -rf $(INFRA_QA)/storage/aurora-db.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: aurora_db_qa destroy_aurora_db_qa refresh_aurora_db_qa plan_aurora_db_qa init_aurora_db_qa clean_aurora_db_qa