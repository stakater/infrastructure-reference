network: plan_network
	cd $(BUILD); \
	$(TF_APPLY) -target module.network.module.vpc \
							-target module.network.module.private_persistence_subnet \
							-target module.network.module.public_subnet \
							-target module.network.module.nat \
							-target module.network.module.network_acl \
							-target module.network.module.private_app_subnet \
							-target module.network;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_network: init_network
	cd $(BUILD); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network;

refresh_network: | $(TF_PROVIDER)
	cd $(BUILD); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network;

destroy_network: | $(TF_PROVIDER)
	cd $(BUILD); \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;
# Bug: While using destroy, it asks for aws region as input from the user
# The region value from provider resource is not passed on to the submodules.
# https://github.com/hashicorp/terraform/issues/1447 (Issue resurfaced after upgrade to TF 0.7)
# https://github.com/hashicorp/terraform/issues/3081

clean_network: destroy_network
	rm -f $(BUILD)/module-network.tf

init_network: init
	cp -rf $(RESOURCES)/terraforms/module-network.tf $(BUILD)
	cd $(BUILD); $(TF_GET);

.PHONY: network destroy_network refresh_network plan_network init_network clean_network

