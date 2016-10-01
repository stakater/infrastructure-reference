utilities_qa: plan_utilities_qa
	cd $(BUILD_QA);

plan_utilities_qa: init_utilities_qa
	cd $(BUILD_QA);

refresh_utilities_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA);

destroy_utilities_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA);

init_utilities_qa: init_qa
		cp -rf $(INFRA_QA)/utilities/*.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: utilities_qa destroy_utilities_qa refresh_utilities_qa plan_utilities_qa init_utilities_qa clean_utilities_qa