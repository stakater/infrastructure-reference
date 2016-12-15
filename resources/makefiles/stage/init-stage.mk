show_stage: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_stage: init
	cat $(BUILD)/terraform.tfstate

graph_stage: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

init_stage: | $(TF_PROVIDER_STAGE) $(MODULE_VARS_STAGE)
	cd $(BUILD_STAGE); \
	mkdir -p policy; \
	mkdir -p user-data; \
	mkdir -p scripts; \
	mkdir -p data; \
	cp -rf $(INFRA_STAGE)/utilities/remote-config.tf $(BUILD_STAGE); \
	$(SCRIPTS)/remote-config.sh -b $(TF_STATE_BUCKET_NAME) -k "$(TF_STATE_STAGE_KEY)"

pull_stage_state:
	cd $(BUILD_STAGE);\
	terraform remote pull;

$(TF_PROVIDER_STAGE): update_provider_stage

$(MODULE_VARS_STAGE): update_vars_stage

update_vars_stage:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_STAGE)

update_provider_stage: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_STAGE)

.PHONY: init_stage show_stage show_state_stage graph_stage refresh_stage update_vars_stage update_provider_stage