utilities_dev: plan_utilities_dev
	cd $(BUILD_DEV); \
	$(TF_APPLY)	-target module.route53-private \
							-target aws_route53_record.docker-registry;

plan_utilities_dev: init_utilities_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target module.route53-private \
						 -target aws_route53_record.docker-registry;

refresh_utilities_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target module.route53-private \
								-target aws_route53_record.docker-registry;

destroy_utilities_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_DESTROY) -target aws_route53_record.docker-registry \
								-target module.route53-private;

init_utilities_dev: init_dev
		cp -rf $(INFRA_DEV)/utilities/*.tf $(BUILD_DEV)
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: utilities_dev destroy_utilities_dev refresh_utilities_dev plan_utilities_dev init_utilities_dev clean_utilities_dev