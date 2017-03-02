prod: storage_prod network_prod utilities_prod efs_prod prod_user_data instance_pool_prod
	cd $(BUILD_PROD); $(TF_REFRESH);
	# Refresh terraform at the end, to make sure all output is present
	# https://github.com/hashicorp/terraform/issues/2598

plan_prod: plan_storage_prod plan_network_prod plan_utilities_prod plan_aurora_db_prod plan_efs_prod plan_prod_user_data plan_instance_pool_prod

refresh_prod: init_prod
	cd $(BUILD_PROD); $(TF_REFRESH)

destroy_prod: destroy_instance_pool_prod destroy_prod_user_data destroy_efs_prod destroy_aurora_db_prod destroy_utilities_prod destroy_network_prod destroy_storage_prod

.PHONY: prod destroy_prod refresh_prod plan_prod