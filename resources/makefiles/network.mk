network: network_global_admiral network_dev network_qa network_prod

plan_network: plan_network_global_admiral plan_network_dev plan_network_qa plan_network_prod

refresh_network: refresh_network_global_admiral refresh_network_dev refresh_network_qa refresh_network_prod

destroy_network: destroy_network_qa destroy_network_dev destroy_network_global_admiral
	@echo -e "\033[0;31m \n\nNOTE:\nnetwork_prod is not destroyed through this command for safety, please destroy it through 'destroy_network_prod' if required \033[0m"

.PHONY: network destroy_network refresh_network plan_network