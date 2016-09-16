peering_global_admiral: peering_dev plan_peering_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_APPLY) -target module.vpc-peering-dev-target;

plan_peering_global_admiral: plan_peering_dev init_peering_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target module.vpc-peering-dev-target;

refresh_peering_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH)  -target module.vpc-peering-dev-target;

destroy_peering_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_DESTROY) -target module.vpc-peering-dev-target;

clean_peering_global_admiral: destroy_peering_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/peering.tf

init_peering_global_admiral: init_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/vpc-peering/*.tf $(BUILD_GLOBAL_ADMIRAL)
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: peering_global_admiral destroy_peering_global_admiral refresh_peering_global_admiral plan_peering_global_admiral init_peering_global_admiral clean_peering_global_admiral