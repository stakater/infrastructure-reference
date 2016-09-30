utilities_dev: plan_utilities_dev
	cd $(BUILD_DEV);

plan_utilities_dev: init_utilities_dev
	cd $(BUILD_DEV);

refresh_utilities_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV);

destroy_utilities_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV);

init_utilities_dev: init_dev
		cp -rf $(INFRA_DEV)/utilities/*.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: utilities_dev destroy_utilities_dev refresh_utilities_dev plan_utilities_dev init_utilities_dev clean_utilities_dev