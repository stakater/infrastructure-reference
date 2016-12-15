utilities_stage: plan_utilities_stage
	cd $(BUILD_STAGE); \
	$(TF_APPLY)	-target module.route53-private \
							-target aws_route53_record.docker-registry;

plan_utilities_stage: init_utilities_stage
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target module.route53-private \
						 -target aws_route53_record.docker-registry;

refresh_utilities_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE);\
	$(TF_REFRESH) -target module.route53-private \
								-target aws_route53_record.docker-registry;

destroy_utilities_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE);\
	$(TF_DESTROY) -target aws_route53_record.docker-registry \
								-target module.route53-private;

init_utilities_stage: init_stage
		cp -rf $(INFRA_STAGE)/utilities/*.tf $(BUILD_STAGE)
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: utilities_stage destroy_utilities_stage refresh_utilities_stage plan_utilities_stage init_utilities_stage clean_utilities_stage