global_admiral: storage_global_admiral network_global_admiral instance_pool_global_admiral

plan_global_admiral: plan_storage_global_admiral plan_network_global_admiral plan_instance_pool_global_admiral

refresh_global_admiral: refresh_storage_global_admiral refresh_network_global_admiral refresh_instance_pool_global_admiral

destroy_global_admiral: destroy_instance_pool_global_admiral destroy_network_global_admiral destroy_storage_global_admiral

.PHONY: global_admiral destroy_global_admiral refresh_global_admiral plan_global_admiral