consul_dev: plan_consul_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c consul-dev; \
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

plan_consul_dev: init_consul_dev
	cd $(BUILD_DEV); \
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

refresh_consul_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
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

destroy_consul_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d consul-dev; \
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

clean_consul_dev: destroy_consul_dev
	rm -f $(BUILD_DEV)/consul.tf

init_consul_dev: init_instance_pool_dev
		cp -rf $(INFRA_DEV)/instance-pool/consul.tf $(BUILD_DEV);
		cp -rf $(INFRA_DEV)/instance-pool/policy/consul* $(BUILD_DEV)/policy;
		cp -rf $(INFRA_DEV)/instance-pool/user-data/consul* $(BUILD_DEV)/user-data;
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: consul_dev destroy_consul_dev refresh_consul_dev plan_consul_dev init_consul_dev clean_consul_dev