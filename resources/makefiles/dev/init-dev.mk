show_dev: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_dev: init
	cat $(BUILD)/terraform.tfstate

graph_dev: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

init_dev: | $(TF_PROVIDER_DEV) $(MODULE_VARS_DEV)
	cd $(BUILD_DEV); \
	mkdir -p policy; \
	mkdir -p user-data; \
	mkdir -p scripts; \
	mkdir -p data; \
	cp -rf $(INFRA_DEV)/utilities/remote-config.tf $(BUILD_DEV); \
	$(SCRIPTS)/remote-config.sh -b $(TF_STATE_BUCKET_NAME) -k "$(TF_STATE_DEV_KEY)"; \

pull_dev_state:
	cd $(BUILD_DEV);\
	terraform remote pull;

$(TF_PROVIDER_DEV): update_provider_dev

$(MODULE_VARS_DEV): update_vars_dev

update_vars_dev:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_DEV)

update_provider_dev: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_DEV)

.PHONY: init_dev show_dev show_state_dev graph_dev refresh_dev update_vars_dev update_provider_dev