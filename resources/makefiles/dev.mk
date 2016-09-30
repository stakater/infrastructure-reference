dev: storage_dev network_dev utilities_dev efs_dev instance_pool_dev
	cd $(BUILD_DEV); $(TF_REFRESH);
	# Refresh dev at the end, to make sure all output is present and as refreshing
	# global admiral state (init_dev) removes peering connections(in the state file only)
	# This is because global admiral is not aware of the peering connections creatied by dev
	# https://github.com/hashicorp/terraform/issues/2598

plan_dev: plan_storage_dev plan_network_dev plan_utilities_dev plan_efs_dev plan_instance_pool_dev

refresh_dev: refresh_storage_dev refresh_network_dev refresh_utilities_dev refresh_efs_dev refresh_instance_pool_dev

destroy_dev: destroy_instance_pool_dev destroy_efs_dev destroy_utilities_dev destroy_network_dev destroy_storage_dev

.PHONY: dev destroy_dev refresh_dev plan_dev