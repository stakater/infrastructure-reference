network_dev: plan_network_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c bastion-host-dev; \
	$(TF_APPLY) -target module.network.module.vpc \
							-target module.network.module.private_persistence_subnet \
							-target module.network.module.public_subnet \
							-target module.network.module.bastion-host \
							-target module.network.module.nat \
							-target module.network.module.network_acl \
							-target module.network.module.private_app_subnet \
							-target module.network.module.vpc-peering \
							-target module.network;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_network_dev: init_network_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.bastion-host \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network.module.vpc-peering \
						 -target module.network;

refresh_network_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.bastion-host \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.vpc-peering \
								-target module.network;

destroy_network_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d bastion-host-dev; \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.vpc-peering \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.bastion-host \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;

clean_network_dev: destroy_network_dev
	rm -f $(BUILD_DEV)/network.tf

init_network_dev: init_dev
		cp -rf $(INFRA_DEV)/network/*.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: network_dev destroy_network_dev refresh_network_dev plan_network_dev init_network_dev clean_network_dev