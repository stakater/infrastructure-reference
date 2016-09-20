prod: storage_prod network_prod

plan_prod: plan_storage_prod plan_network_prod

refresh_prod: refresh_storage_prod refresh_network_prod

destroy_prod: destroy_storage_prod destroy_network_prod

.PHONY: prod destroy_prod refresh_prod plan_prod