admiral_dev: plan_admiral_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c admiral-dev; \
	$(TF_APPLY) -target aws_s3_bucket_object.admiral-cloud-config \
	            -target module.admiral.module.launch-configuration \
							-target module.admiral.module.auto-scaling-group \
							-target module.admiral-scale-up-policy \
							-target module.admiral-scale-down-policy \
							-target aws_security_group_rule.sg-admiral-ssh \
							-target aws_security_group_rule.sg-admiral-outgoing \
							-target aws_security_group_rule.sg-admiral-5601 \
							-target aws_security_group_rule.sg-admiral-5044 \
							-target aws_security_group_rule.sg-admiral-9200 \
							-target aws_security_group_rule.sg-admiral-9300 \
							-target aws_security_group_rule.sg-admiral-fleet \
	 						-target aws_elb.admiral-elb \
	 						-target aws_elb.admiral-elb-internal \
							-target aws_route53_record.admiral \
							-target aws_route53_record.admiral-internal \
							-target module.admiral;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_admiral_dev: init_admiral_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target aws_s3_bucket_object.admiral-cloud-config \
	           -target module.admiral.module.launch-configuration \
						 -target module.admiral.module.auto-scaling-group \
						 -target module.admiral-scale-up-policy \
						 -target module.admiral-scale-down-policy \
						 -target aws_security_group_rule.sg-admiral-ssh \
						 -target aws_security_group_rule.sg-admiral-outgoing \
						 -target aws_security_group_rule.sg-admiral \
						 -target aws_security_group_rule.sg-admiral-5601 \
						 -target aws_security_group_rule.sg-admiral-5044 \
						 -target aws_security_group_rule.sg-admiral-9200 \
						 -target aws_security_group_rule.sg-admiral-9300 \
						 -target aws_security_group_rule.sg-admiral-fleet \
						 -target aws_elb.admiral-elb \
						 -target aws_elb.admiral-elb-internal \
						 -target aws_route53_record.admiral \
						 -target aws_route53_record.admiral-internal \
						 -target module.admiral;

refresh_admiral_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target aws_s3_bucket_object.admiral-cloud-config \
	              -target module.admiral.module.launch-configuration \
								-target module.admiral.module.auto-scaling-group \
								-target module.admiral-scale-up-policy \
								-target module.admiral-scale-down-policy \
								-target aws_security_group_rule.sg-admiral-ssh \
								-target aws_security_group_rule.sg-admiral-outgoing \
								-target aws_security_group_rule.sg-admiral \
								-target aws_security_group_rule.sg-admiral-5601 \
								-target aws_security_group_rule.sg-admiral-5044 \
								-target aws_security_group_rule.sg-admiral-9200 \
								-target aws_security_group_rule.sg-admiral-9300 \
								-target aws_security_group_rule.sg-admiral-fleet \
								-target aws_elb.admiral-elb \
								-target aws_elb.admiral-elb-internal \
								-target aws_security_group.admiral-sg-elb \
								-target aws_route53_record.admiral \
								-target aws_route53_record.admiral-internal \
								-target module.admiral;

destroy_admiral_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d admiral-dev; \
	$(TF_DESTROY) -target module.admiral \
								-target aws_security_group_rule.sg-admiral-ssh \
								-target aws_security_group_rule.sg-admiral-outgoing \
								-target aws_security_group_rule.sg-admiral \
								-target aws_security_group_rule.sg-admiral-5601 \
								-target aws_security_group_rule.sg-admiral-5044 \
								-target aws_security_group_rule.sg-admiral-9200 \
								-target aws_security_group_rule.sg-admiral-9300 \
								-target aws_security_group_rule.sg-admiral-fleet \
								-target module.admiral-scale-up-policy \
								-target module.admiral-scale-down-policy \
								-target module.admiral.module.auto-scaling-group \
								-target module.admiral.module.launch-configuration \
								-target aws_elb.admiral-elb \
								-target aws_elb.admiral-elb-internal \
								-target aws_route53_record.admiral \
								-target aws_route53_record.admiral-internal \
								-target aws_security_group.admiral-sg-elb \
								-target aws_s3_bucket_object.admiral-cloud-config;

clean_admiral_dev: destroy_admiral_dev
	rm -f $(BUILD_DEV)/admiral.tf

init_admiral_dev: init_instance_pool_dev
		cp -rf $(INFRA_DEV)/instance-pool/admiral.tf $(BUILD_DEV);
		cp -rf $(INFRA_DEV)/instance-pool/policy/admiral* $(BUILD_DEV)/policy;
		cp -rf $(INFRA_DEV)/instance-pool/user-data/admiral* $(BUILD_DEV)/user-data;
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: admiral_dev destroy_admiral_dev refresh_admiral_dev plan_admiral_dev init_admiral_dev clean_admiral_dev