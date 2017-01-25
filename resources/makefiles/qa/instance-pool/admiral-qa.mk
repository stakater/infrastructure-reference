admiral_qa: plan_admiral_qa
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -c admiral-qa; \
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

plan_admiral_qa: init_admiral_qa
	cd $(BUILD_QA); \
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

refresh_admiral_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
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

destroy_admiral_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -d admiral-qa; \
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

clean_admiral_qa: destroy_admiral_qa
	rm -f $(BUILD_QA)/admiral.tf

init_admiral_qa: init_instance_pool_qa
		cp -rf $(INFRA_QA)/instance-pool/admiral.tf $(BUILD_QA);
		cp -rf $(INFRA_QA)/instance-pool/policy/admiral* $(BUILD_QA)/policy;
		cp -rf $(INFRA_QA)/instance-pool/user-data/admiral* $(BUILD_QA)/user-data;
		cd $(BUILD_QA); $(TF_GET);

.PHONY: admiral_qa destroy_admiral_qa refresh_admiral_qa plan_admiral_qa init_admiral_qa clean_admiral_qa