dev: storage_dev network_dev utilities_dev efs_dev instance_pool_dev

plan_dev: plan_storage_dev plan_network_dev plan_utilities_dev plan_efs_dev plan_instance_pool_dev

refresh_dev: init_dev
	cd $(BUILD_DEV); $(TF_REFRESH)

destroy_dev: destroy_instance_pool_dev destroy_efs_dev destroy_aurora_db_dev destroy_utilities_dev destroy_network_dev destroy_storage_dev

.PHONY: dev destroy_dev refresh_dev plan_dev