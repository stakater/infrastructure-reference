house_keeper_global_admiral: plan_house_keeper_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c house-keeper; \
	$(TF_APPLY) -target aws_s3_bucket_object.house-keeper-cloud-config \
	            -target module.house-keeper.module.launch-configuration \
							-target module.house-keeper.module.auto-scaling-group \
							-target aws_security_group_rule.sg-house-keeper-ssh \
							-target aws_security_group_rule.sg-house-keeper-outgoing \
							-target aws_security_group_rule.sg-house-keeper \
							-target module.house-keeper;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_house_keeper_global_admiral: init_house_keeper_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target aws_s3_bucket_object.house-keeper-cloud-config \
	           -target module.house-keeper.module.launch-configuration \
						 -target module.house-keeper.module.auto-scaling-group \
						 -target aws_security_group_rule.sg-house-keeper-ssh \
						 -target aws_security_group_rule.sg-house-keeper-outgoing \
						 -target aws_security_group_rule.sg-house-keeper \
						 -target module.house-keeper;

refresh_house_keeper_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target aws_s3_bucket_object.house-keeper-cloud-config \
	              -target module.house-keeper.module.launch-configuration \
								-target aws_security_group.worker-sg-elb \
                                -target module.house-keeper.module.auto-scaling-group \
								-target aws_security_group_rule.sg-house-keeper-ssh \
								-target aws_security_group_rule.sg-house-keeper-outgoing \
								-target aws_security_group_rule.sg-house-keeper \
								-target module.house-keeper;

destroy_house_keeper_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d house-keeper; \
	$(TF_DESTROY) -target module.house-keeper \
								-target aws_security_group_rule.sg-house-keeper-ssh \
								-target aws_security_group_rule.sg-house-keeper-outgoing \
								-target aws_security_group_rule.sg-house-keeper \
								-target aws_security_group.worker-sg-elb \
								-target module.house-keeper.module.auto-scaling-group \
								-target module.house-keeper.module.launch-configuration \
								-target aws_s3_bucket_object.house-keeper-cloud-config;

clean_house_keeper_global_admiral: destroy_house_keeper_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/house-keeper.tf

init_house_keeper_global_admiral: init_instance_pool_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/house-keeper.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/house-keeper* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/house-keeper* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: house_keeper_global_admiral destroy_house_keeper_global_admiral refresh_house_keeper_global_admiral plan_house_keeper_global_admiral init_house_keeper_global_admiral clean_house_keeper_global_admiral