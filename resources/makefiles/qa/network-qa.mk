network_qa: plan_network_qa
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -c bastion-host-qa; \
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

plan_network_qa: init_network_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target module.network.module.vpc \
	           -target module.network.module.private_persistence_subnet \
						 -target module.network.module.public_subnet \
						 -target module.network.module.bastion-host \
						 -target module.network.module.nat \
						 -target module.network.module.network_acl \
						 -target module.network.module.private_app_subnet \
						 -target module.network.module.vpc-peering \
						 -target module.network;

refresh_network_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target module.network.module.vpc \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.public_subnet \
								-target module.network.module.bastion-host \
								-target module.network.module.nat \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.vpc-peering \
								-target module.network;

destroy_network_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_DESTROY) -target module.network \
								-target module.network.module.vpc-peering \
								-target module.network.module.network_acl \
								-target module.network.module.private_app_subnet \
								-target module.network.module.nat \
								-target module.network.module.bastion-host \
								-target module.network.module.public_subnet \
								-target module.network.module.private_persistence_subnet \
								-target module.network.module.vpc;

clean_network_qa: destroy_network_qa
	rm -f $(BUILD_QA)/network.tf

init_network_qa: init_qa
		cp -rf $(INFRA_QA)/network/*.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: network_qa destroy_network_qa refresh_network_qa plan_network_qa init_network_qa clean_network_qa