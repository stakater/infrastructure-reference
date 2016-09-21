qa: storage_qa network_qa

plan_qa: plan_storage_qa plan_network_qa

refresh_qa: refresh_storage_qa refresh_network_qa

destroy_qa: destroy_network_qa destroy_storage_qa

.PHONY: qa destroy_qa refresh_qa plan_qa