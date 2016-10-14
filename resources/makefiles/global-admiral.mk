global_admiral: storage_global_admiral network_global_admiral utilities_global_admiral instance_pool_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); $(TF_REFRESH);
	# Refresh terraform at the end, to make sure all output is present
	# https://github.com/hashicorp/terraform/issues/2598

plan_global_admiral: plan_storage_global_admiral plan_network_global_admiral plan_utilities_global_admiral plan_instance_pool_global_admiral

refresh_global_admiral: init_global_admiral
	cd $(BUILD); $(TF_REFRESH)

destroy_global_admiral: destroy_instance_pool_global_admiral destroy_utilities_global_admiral destroy_network_global_admiral destroy_storage_global_admiral

.PHONY: global_admiral destroy_global_admiral refresh_global_admiral plan_global_admiral