show_prod: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_prod: init
	cat $(BUILD)/terraform.tfstate

graph_prod: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

refresh_prod: init_prod
	cd $(BUILD); $(TF_REFRESH)

init_prod: | $(TF_PROVIDER_PROD) $(MODULE_VARS_PROD)

$(TF_PROVIDER_PROD): update_provider_prod

$(MODULE_VARS_PROD): update_vars_prod

update_vars_prod:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_PROD)

update_provider_prod: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_PROD)

.PHONY: init_prod show_prod show_state_prod graph_prod refresh_prod update_vars_prod update_provider_prod