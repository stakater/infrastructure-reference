# Separate from storage because needs to made after network
efs_prod: plan_efs_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY)	-target module.efs \
							-target module.efs-mount-targets;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_efs_prod: init_efs_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target module.efs \
						 -target module.efs-mount-targets;

refresh_efs_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.efs \
								-target module.efs-mount-targets;

destroy_efs_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_DESTROY) -target module.efs \
								-target module.efs-mount-targets;

clean_efs_prod: destroy_efs_prod
	rm -f $(BUILD_PROD)/efs.tf

init_efs_prod: init_prod
		cp -rf $(INFRA_PROD)/storage/efs.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: efs_prod destroy_efs_prod refresh_efs_prod plan_efs_prod init_efs_prod clean_efs_prod