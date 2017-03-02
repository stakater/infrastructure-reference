consul_prod: plan_consul_prod
	cd $(BUILD_PROD); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -c consul-prod; \
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

plan_consul_prod: init_consul_prod
	cd $(BUILD_PROD); \
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

refresh_consul_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
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

destroy_consul_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -d consul-prod; \
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

clean_consul_prod: destroy_consul_prod
	rm -f $(BUILD_PROD)/consul.tf

init_consul_prod: init_instance_pool_prod
		cp -rf $(INFRA_PROD)/instance-pool/consul.tf $(BUILD_PROD);
		cp -rf $(INFRA_PROD)/instance-pool/policy/consul* $(BUILD_PROD)/policy;
		cp -rf $(INFRA_PROD)/instance-pool/user-data/consul* $(BUILD_PROD)/user-data;
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: consul_prod destroy_consul_prod refresh_consul_prod plan_consul_prod init_consul_prod clean_consul_prod