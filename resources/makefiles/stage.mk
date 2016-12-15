stage: storage_stage network_stage utilities_stage efs_stage stage_user_data instance_pool_stage
	cd $(BUILD_STAGE); $(TF_REFRESH);
	# Refresh terraform at the end, to make sure all output is present
	# https://github.com/hashicorp/terraform/issues/2598

plan_stage: plan_storage_stage plan_network_stage plan_utilities_stage plan_efs_stage plan_stage_user_data plan_instance_pool_stage

refresh_stage: init_stage
	cd $(BUILD_STAGE); $(TF_REFRESH)

destroy_stage: destroy_instance_pool_stage destroy_stage_user_data destroy_efs_stage destroy_utilities_stage destroy_network_stage destroy_storage_stage

.PHONY: stage destroy_stage refresh_stage plan_stage