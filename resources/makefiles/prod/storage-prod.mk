storage_prod: plan_storage_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY)	-target module.config-bucket;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_prod: init_storage_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target module.config-bucket;

refresh_storage_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.config-bucket;

destroy_storage_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_DESTROY) -target module.config-bucket;

clean_storage_prod: destroy_storage_prod
	rm -f $(BUILD_PROD)/storage.tf

init_storage_prod: init_prod
		cp -rf $(INFRA_PROD)/storage/*.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: storage_prod destroy_storage_prod refresh_storage_prod plan_storage_prod init_storage_prod clean_storage_prod