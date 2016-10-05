utilities_qa: plan_utilities_qa
	cd $(BUILD_QA); \
	$(TF_APPLY)	-target module.route53-private \
							-target aws_route53_record.docker-registry;

plan_utilities_qa: init_utilities_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target module.route53-private \
						 -target aws_route53_record.docker-registry;

refresh_utilities_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target module.route53-private \
								-target aws_route53_record.docker-registry;


destroy_utilities_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA);\
	$(TF_DESTROY) -target aws_route53_record.docker-registry \
								-target module.route53-private;


init_utilities_qa: init_qa
		cp -rf $(INFRA_QA)/utilities/*.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: utilities_qa destroy_utilities_qa refresh_utilities_qa plan_utilities_qa init_utilities_qa clean_utilities_qa