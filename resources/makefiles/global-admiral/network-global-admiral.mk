network_global_admiral: plan_network_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_APPLY) -target module.network.module.vpc \
							-target module.network.module.private_persistence_subnet \
							-target module.network.module.public_subnet \
							-target module.network.module.nat \
							-target module.network.module.network_acl \
							-target module.network.module.private_app_subnet \
							-target module.network;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_network_global_admiral: init_network_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network;

refresh_network_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network;

destroy_network_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;

clean_network_global_admiral: destroy_network_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/network.tf

init_network_global_admiral: init_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/network/*.tf $(BUILD_GLOBAL_ADMIRAL)
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: network_global_admiral destroy_network_global_admiral refresh_network_global_admiral plan_network_global_admiral init_network_global_admiral clean_network_global_admiral