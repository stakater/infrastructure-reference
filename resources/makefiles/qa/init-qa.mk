show_qa: | $(BUILD)
	cd $(BUILD); $(TF_SHOW)

show_state_qa: init
	cat $(BUILD)/terraform.tfstate

graph_qa: | $(BUILD)
	cd $(BUILD); $(TF_GRAPH)

refresh_qa: init_qa
	cd $(BUILD); $(TF_REFRESH)

init_qa: | $(TF_PROVIDER_QA) $(MODULE_VARS_QA)
	cd $(BUILD_QA); \
	mkdir -p policy; \
	mkdir -p user-data; \
	mkdir -p scripts; \
	mkdir -p data; \
	cp -rf $(INFRA_QA)/utilities/remote-config.tf $(BUILD_QA); \
	$(SCRIPTS)/remote-config.sh -b $(TF_STATE_BUCKET_NAME) -k "$(TF_STATE_QA_KEY)"

pull_qa_state:
	cd $(BUILD_QA);\
	terraform remote pull;

$(TF_PROVIDER_QA): update_provider_qa

$(MODULE_VARS_QA): update_vars_qa

update_vars_qa:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-vars.sh > $(MODULE_VARS_QA)

update_provider_qa: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > $(TF_PROVIDER_QA)

.PHONY: init_qa show_qa show_state_qa graph_qa refresh_qa update_vars_qa update_provider_qa