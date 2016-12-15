network_stage: plan_network_stage
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -c bastion-host-stage; \
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

plan_network_stage: init_network_stage
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.bastion-host \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network.module.vpc-peering \
						 -target module.network;

refresh_network_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.bastion-host \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.vpc-peering \
								-target module.network;

destroy_network_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -d bastion-host-stage; \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.vpc-peering \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.bastion-host \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;

clean_network_stage: destroy_network_stage
	rm -f $(BUILD_STAGE)/network.tf

init_network_stage: init_stage
		cp -rf $(INFRA_STAGE)/network/*.tf $(BUILD_STAGE)
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: network_stage destroy_network_stage refresh_network_stage plan_network_stage init_network_stage clean_network_stage