# Separate from storage because needs to made after network
efs_stage: plan_efs_stage
	cd $(BUILD_STAGE); \
	$(TF_APPLY)	-target module.efs \
							-target module.efs-mount-targets;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_efs_stage: init_efs_stage
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target module.efs \
						 -target module.efs-mount-targets;

refresh_efs_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_REFRESH) -target module.efs \
								-target module.efs-mount-targets;

destroy_efs_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_DESTROY) -target module.efs \
								-target module.efs-mount-targets;

clean_efs_stage: destroy_efs_stage
	rm -f $(BUILD_STAGE)/efs.tf

init_efs_stage: init_stage
		cp -rf $(INFRA_STAGE)/storage/efs.tf $(BUILD_STAGE)
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: efs_stage destroy_efs_stage refresh_efs_stage plan_efs_stage init_efs_stage clean_efs_stage