consul_stage: plan_consul_stage
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -c consul-stage; \
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
							-target aws_security_group_rule.sg-consul-etcd \
							-target aws_route53_record.consul \
							-target module.consul;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_consul_stage: init_consul_stage
	cd $(BUILD_STAGE); \
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
						 -target aws_security_group_rule.sg-consul-etcd \
						 -target module.consul;

refresh_consul_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
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
								-target aws_security_group_rule.sg-consul-etcd \
								-target aws_route53_record.consul \
								-target aws_elb.consul-elb \
								-target aws_security_group.consul-sg-elb \
								-target module.consul;

destroy_consul_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -d consul-stage; \
	$(TF_DESTROY) -target module.consul \
								-target aws_security_group_rule.sg-consul-ssh \
								-target aws_security_group_rule.sg-consul-outgoing \
								-target aws_security_group_rule.sg-consul \
								-target aws_security_group_rule.sg-consul-8300 \
								-target aws_security_group_rule.sg-consul-8301 \
								-target aws_security_group_rule.sg-consul-8400 \
								-target aws_security_group_rule.sg-consul-8500 \
								-target aws_security_group_rule.sg-consul-etcd \
								-target module.consul_scale_up_policy \
								-target module.consul_scale_down_policy \
								-target module.consul.module.auto-scaling-group \
								-target module.consul.module.launch-configuration \
								-target aws_route53_record.consul \
								-target aws_elb.consul-elb \
								-target aws_security_group.consul-sg-elb \
								-target aws_s3_bucket_object.consul_cloud_config;

clean_consul_stage: destroy_consul_stage
	rm -f $(BUILD_STAGE)/consul.tf

init_consul_stage: init_instance_pool_stage
		cp -rf $(INFRA_STAGE)/instance-pool/consul.tf $(BUILD_STAGE);
		cp -rf $(INFRA_STAGE)/instance-pool/policy/consul* $(BUILD_STAGE)/policy;
		cp -rf $(INFRA_STAGE)/instance-pool/user-data/consul* $(BUILD_STAGE)/user-data;
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: consul_stage destroy_consul_stage refresh_consul_stage plan_consul_stage init_consul_stage clean_consul_stage