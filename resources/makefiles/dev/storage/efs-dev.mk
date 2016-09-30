# Separate from storage because needs to made after network
efs_dev: plan_efs_dev
	cd $(BUILD_DEV); \
	$(TF_APPLY)	-target module.efs \
							-target module.efs-mount-targets;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_efs_dev: init_efs_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.efs \
						 -target module.efs-mount-targets;

refresh_efs_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target module.efs \
								-target module.efs-mount-targets;

destroy_efs_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_DESTROY) -target module.efs \
								-target module.efs-mount-targets;

clean_efs_dev: destroy_efs_dev
	rm -f $(BUILD_DEV)/efs.tf

init_efs_dev: init_dev
		cp -rf $(INFRA_DEV)/storage/efs.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: efs_dev destroy_efs_dev refresh_efs_dev plan_efs_dev init_efs_dev clean_efs_dev