utilities_prod: plan_utilities_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY)	-target module.route53-private \
							-target aws_route53_record.docker-registry;

plan_utilities_prod: init_utilities_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target module.route53-private \
						 -target aws_route53_record.docker-registry;

refresh_utilities_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD);\
	$(TF_REFRESH) -target module.route53-private \
								-target aws_route53_record.docker-registry;

destroy_utilities_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD);\
	$(TF_DESTROY) -target aws_route53_record.docker-registry \
								-target module.route53-private;

init_utilities_prod: init_prod
		cp -rf $(INFRA_PROD)/utilities/*.tf $(BUILD_PROD)
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: utilities_prod destroy_utilities_prod refresh_utilities_prod plan_utilities_prod init_utilities_prod clean_utilities_prod