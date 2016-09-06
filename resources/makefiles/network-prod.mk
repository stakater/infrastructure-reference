network_prod: plan_network_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY) -target module.network.module.vpc \
							-target module.network.module.private_persistence_subnet \
							-target module.network.module.public_subnet \
							-target module.network.module.nat \
							-target module.network.module.network_acl \
							-target module.network.module.private_app_subnet \
							-target module.network;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_network_prod: init_network_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network;

refresh_network_prod: | $(TF_PROVIDER_PROD)
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network;

destroy_network_prod: | $(TF_PROVIDER_PROD)
	cd $(BUILD_PROD); \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;

clean_network_prod: destroy_network_prod
	rm -f $(BUILD_PROD)/network.tf

init_network_prod: init_prod
		cp -rf $(INFRA_PROD)/network/*.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: network_prod destroy_network_prod refresh_network_prod plan_network_prod init_network_prod clean_network_prod