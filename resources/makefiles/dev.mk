dev: storage_dev network_dev

plan_dev: plan_storage_dev plan_network_dev

refresh_dev: refresh_storage_dev refresh_network_dev

destroy_dev: destroy_storage_dev destroy_network_dev

.PHONY: dev destroy_dev refresh_dev plan_dev