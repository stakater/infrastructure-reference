storage_dev: plan_storage_dev
	cd $(BUILD_DEV); \
	$(TF_APPLY)	-target module.config-bucket;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_dev: init_storage_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.config-bucket;

refresh_storage_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target module.config-bucket;

destroy_storage_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_DESTROY) -target module.config-bucket;

clean_storage_dev: destroy_storage_dev
	rm -f $(BUILD_DEV)/storage.tf

init_storage_dev: init_dev
		cp -rf $(INFRA_DEV)/storage/*.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: storage_dev destroy_storage_dev refresh_storage_dev plan_storage_dev init_storage_dev clean_storage_dev