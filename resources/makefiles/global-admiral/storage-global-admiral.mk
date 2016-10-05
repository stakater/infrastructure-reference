storage_global_admiral: plan_storage_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_APPLY)	-target module.config-bucket \
							-target module.cloudinit-bucket;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_global_admiral: init_storage_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target module.config-bucket \
						 -target module.cloudinit-bucket;

refresh_storage_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target module.config-bucket \
								-target module.cloudinit-bucket;

destroy_storage_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_DESTROY) -target module.cloudinit-bucket \
								-target module.config-bucket;

clean_storage_global_admiral: destroy_storage_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/storage.tf

init_storage_global_admiral: init_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/storage/storage.tf $(BUILD_GLOBAL_ADMIRAL)
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: storage_global_admiral destroy_storage_global_admiral refresh_storage_global_admiral plan_storage_global_admiral init_storage_global_admiral clean_storage_global_admiral