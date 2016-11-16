qa: storage_qa network_qa utilities_qa  efs_qa instance_pool_qa

plan_qa: plan_storage_qa plan_network_qa plan_utilities_qa plan_efs_qa plan_instance_pool_qa

refresh_qa: init_qa
	cd $(BUILD_QA); $(TF_REFRESH)

destroy_qa: destroy_instance_pool_qa destroy_efs_qa destroy_aurora_db_qa destroy_utilities_qa destroy_network_qa destroy_storage_qa

.PHONY: qa destroy_qa refresh_qa plan_qa