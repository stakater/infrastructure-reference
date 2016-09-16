peering_dev:  plan_peering_dev
	cd $(BUILD_DEV); \
	$(TF_APPLY) -target module.vpc-peering-ga-root;

plan_peering_dev: init_peering_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.vpc-peering-ga-root;

refresh_peering_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH)  -target module.vpc-peering-ga-root;

destroy_peering_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_DESTROY) -target module.vpc-peering-ga-root;

clean_peering_dev: destroy_peering_dev
	rm -f $(BUILD_DEV)/peering.tf

init_peering_dev: init_dev
		cp -rf $(INFRA_DEV)/vpc-peering/*.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: peering_dev destroy_peering_dev refresh_peering_dev plan_peering_dev init_peering_dev clean_peering_dev