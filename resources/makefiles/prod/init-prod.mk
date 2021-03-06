show_prod: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_prod: init
	cat $(BUILD)/terraform.tfstate

graph_prod: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

init_prod: | $(TF_PROVIDER_PROD) $(MODULE_VARS_PROD)
	cd $(BUILD_PROD); \
	mkdir -p policy; \
	mkdir -p user-data; \
	mkdir -p scripts; \
	mkdir -p data; \
	cp -rf $(INFRA_PROD)/utilities/remote-config.tf $(BUILD_PROD); \
	$(SCRIPTS)/remote-config.sh -b $(TF_STATE_BUCKET_NAME) -k "$(TF_STATE_PROD_KEY)"

pull_prod_state:
	cd $(BUILD_PROD);\
	terraform remote pull;

$(TF_PROVIDER_PROD): update_provider_prod

$(MODULE_VARS_PROD): update_vars_prod

update_vars_prod:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_PROD)

update_provider_prod: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_PROD)

.PHONY: init_prod show_prod show_state_prod graph_prod refresh_prod update_vars_prod update_provider_prod