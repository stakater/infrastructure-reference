show_qa: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_qa: init
	cat $(BUILD)/terraform.tfstate

graph_qa: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

refresh_qa: init_qa
	cd $(BUILD); $(TF_REFRESH)

init_qa: | $(TF_PROVIDER_QA) $(MODULE_VARS_QA)

$(TF_PROVIDER_QA): update_provider_qa

$(MODULE_VARS_QA): update_vars_qa

update_vars_qa:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_QA)

update_provider_qa: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_QA)

.PHONY: init_qa show_qa show_state_qa graph_qa refresh_qa update_vars_qa update_provider_qa