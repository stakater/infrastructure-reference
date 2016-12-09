storage_stage: plan_storage_stage
	cd $(BUILD_STAGE); \
	$(TF_APPLY)	-target module.config-bucket \
							-target module.cloudinit-bucket;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_stage: init_storage_stage
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target module.config-bucket \
						 -target module.cloudinit-bucket;

refresh_storage_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_REFRESH) -target module.config-bucket \
								-target module.cloudinit-bucket;

destroy_storage_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_DESTROY) -target module.config-bucket \
								-target module.cloudinit-bucket;

clean_storage_stage: destroy_storage_stage
	rm -f $(BUILD_STAGE)/storage.tf

init_storage_stage: init_stage
		cp -rf $(INFRA_STAGE)/storage/storage.tf $(BUILD_STAGE)
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: storage_stage destroy_storage_stage refresh_storage_stage plan_storage_stage init_storage_stage clean_storage_stage