consul_qa: plan_consul_qa
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -c consul-qa; \
	$(TF_APPLY) -target aws_s3_bucket_object.consul_cloud_config \
	            -target module.consul.module.launch-configuration \
				-target module.consul.module.auto-scaling-group \
				-target module.consul_scale_up_policy \
				-target module.consul_scale_down_policy \
				-target aws_security_group_rule.sg-consul-ssh \
				-target aws_security_group_rule.sg-consul-outgoing \
				-target aws_security_group_rule.sg-consul-8300 \
				-target aws_security_group_rule.sg-consul-8301 \
				-target aws_security_group_rule.sg-consul-8400 \
				-target aws_security_group_rule.sg-consul-8500 \
				-target aws_route53_record.consul \
				-target module.consul;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_consul_qa: init_consul_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target aws_s3_bucket_object.consul_cloud_config \
	           -target module.consul.module.launch-configuration \
				 -target module.consul.module.auto-scaling-group \
				 -target module.consul_scale_up_policy \
				 -target module.consul_scale_down_policy \
				 -target aws_security_group_rule.sg-consul-ssh \
				 -target aws_security_group_rule.sg-consul-outgoing \
				 -target aws_security_group_rule.sg-consul \
				 -target aws_security_group_rule.sg-consul-8300 \
				 -target aws_security_group_rule.sg-consul-8301 \
				 -target aws_security_group_rule.sg-consul-8400 \
				 -target aws_security_group_rule.sg-consul-8500 \
				 -target module.consul;

refresh_consul_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target aws_s3_bucket_object.consul_cloud_config \
	              -target module.consul.module.launch-configuration \
					-target module.consul.module.auto-scaling-group \
					-target module.consul_scale_up_policy \
					-target module.consul_scale_down_policy \
					-target aws_security_group_rule.sg-consul-ssh \
					-target aws_security_group_rule.sg-consul-outgoing \
					-target aws_security_group_rule.sg-consul \
					-target aws_security_group_rule.sg-consul-8300 \
					-target aws_security_group_rule.sg-consul-8301 \
					-target aws_security_group_rule.sg-consul-8400 \
					-target aws_security_group_rule.sg-consul-8500 \
					-target aws_route53_record.consul \
					-target aws_elb.consul-elb \
					-target aws_security_group.consul-sg-elb \
					-target module.consul;

destroy_consul_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -d consul-qa; \
	$(TF_DESTROY) -target module.consul \
					-target aws_security_group_rule.sg-consul-ssh \
					-target aws_security_group_rule.sg-consul-outgoing \
					-target aws_security_group_rule.sg-consul \
					-target aws_security_group_rule.sg-consul-8300 \
					-target aws_security_group_rule.sg-consul-8301 \
					-target aws_security_group_rule.sg-consul-8400 \
					-target aws_security_group_rule.sg-consul-8500 \
					-target module.consul_scale_up_policy \
					-target module.consul_scale_down_policy \
					-target module.consul.module.auto-scaling-group \
					-target module.consul.module.launch-configuration \
					-target aws_route53_record.consul \
					-target aws_elb.consul-elb \
					-target aws_security_group.consul-sg-elb \
					-target aws_s3_bucket_object.consul_cloud_config;

clean_consul_qa: destroy_consul_qa
	rm -f $(BUILD_QA)/consul.tf

init_consul_qa: init_instance_pool_qa
		cp -rf $(INFRA_QA)/instance-pool/consul.tf $(BUILD_QA);
		cp -rf $(INFRA_QA)/instance-pool/policy/consul* $(BUILD_QA)/policy;
		cp -rf $(INFRA_QA)/instance-pool/user-data/consul* $(BUILD_QA)/user-data;
		cd $(BUILD_QA); $(TF_GET);

.PHONY: consul_qa destroy_consul_qa refresh_consul_qa plan_consul_qa init_consul_qa clean_consul_qa