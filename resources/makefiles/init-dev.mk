show_dev: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_dev: init
	cat $(BUILD)/terraform.tfstate

graph_dev: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

refresh_dev: init_dev
	cd $(BUILD); $(TF_REFRESH)

init_dev: | $(TF_PROVIDER_DEV) $(MODULE_VARS_DEV)

$(TF_PROVIDER_DEV): update_provider_dev

$(MODULE_VARS_DEV): update_vars_dev

update_vars_dev:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_DEV)

update_provider_dev: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_DEV)

.PHONY: init_dev show_dev show_state_dev graph_dev refresh_dev update_vars_dev update_provider_dev