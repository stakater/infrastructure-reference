utilities_prod: plan_utilities_prod
	cd $(BUILD_PROD);

plan_utilities_prod: init_utilities_prod
	cd $(BUILD_PROD);

refresh_utilities_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD);

destroy_utilities_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD);

init_utilities_prod: init_prod
		cp -rf $(INFRA_PROD)/utilities/*.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: utilities_prod destroy_utilities_prod refresh_utilities_prod plan_utilities_prod init_utilities_prod clean_utilities_prod