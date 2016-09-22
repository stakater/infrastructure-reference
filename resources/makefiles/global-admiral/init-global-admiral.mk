show_global_admiral: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_global_admiral: init
	cat $(BUILD)/terraform.tfstate

graph_global_admiral: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

refresh_global_admiral: init_global_admiral
	cd $(BUILD); $(TF_REFRESH)

init_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) $(MODULE_VARS_GLOBAL_ADMIRAL)
	cd $(BUILD_GLOBAL_ADMIRAL); \
	mkdir -p policy; \
	mkdir -p user-data; \
	$(SCRIPTS)/remote-config.sh -b $(TF_STATE_BUCKET_NAME) -k "global-admiral/terraform.tfstate"

pull_global_admiral_state:
	cd $(BUILD_GLOBAL_ADMIRAL);\
	terraform remote pull;

$(TF_PROVIDER_GLOBAL_ADMIRAL): update_provider_global_admiral

$(MODULE_VARS_GLOBAL_ADMIRAL): update_vars_global_admiral

update_vars_global_admiral:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_GLOBAL_ADMIRAL)

update_provider_global_admiral: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_GLOBAL_ADMIRAL)

.PHONY: init_global_admiral show_global_admiral show_state_global_admiral graph_global_admiral refresh_global_admiral update_vars_global_admiral update_provider_global_admiral