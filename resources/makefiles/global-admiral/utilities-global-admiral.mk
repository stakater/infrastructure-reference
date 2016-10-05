utilities_global_admiral: plan_utilities_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_APPLY)	-target module.route53-private;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_utilities_global_admiral: init_utilities_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target module.route53-private;

refresh_utilities_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target module.route53-private;

destroy_utilities_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_DESTROY) -target module.route53-private;

init_utilities_global_admiral: init_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/utilities/*.tf $(BUILD_GLOBAL_ADMIRAL)
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: utilities_global_admiral destroy_utilities_global_admiral refresh_utilities_global_admiral plan_utilities_global_admiral init_utilities_global_admiral clean_utilities_global_admiral