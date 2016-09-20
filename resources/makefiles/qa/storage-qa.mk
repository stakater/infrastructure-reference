storage_qa: plan_storage_qa
	cd $(BUILD_QA); \
	$(TF_APPLY)	-target module.config-bucket;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_qa: init_storage_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target module.config-bucket;

refresh_storage_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target module.config-bucket;

destroy_storage_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_DESTROY) -target module.config-bucket;

clean_storage_qa: destroy_storage_qa
	rm -f $(BUILD_QA)/storage.tf

init_storage_qa: init_qa
		cp -rf $(INFRA_QA)/storage/*.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: storage_qa destroy_storage_qa refresh_storage_qa plan_storage_qa init_storage_qa clean_storage_qa