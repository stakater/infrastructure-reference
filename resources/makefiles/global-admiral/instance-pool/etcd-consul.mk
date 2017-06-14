etcd_consul_global_admiral: plan_etcd_consul_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c etcd-consul; \
	$(TF_APPLY) -target aws_s3_bucket_object.etcd_consul_cloud_config \
	            -target module.etcd-consul.module.launch-configuration \
							-target module.etcd_consul.module.auto-scaling-group \
							-target module.etcd_consul_scale_up_policy \
							-target module.etcd_consul_scale_down_policy \
							-target aws_security_group_rule.sg-etcd-consul-ssh \
							-target aws_security_group_rule.sg-etcd-consul-outgoing \
							-target aws_security_group_rule.sg-etcd \
							-target aws_security_group_rule.sg-fleet \
							-target aws_security_group_rule.sg-consul-ui \
							-target aws_security_group_rule.sg-consul-cluster \
							-target module.etcd-consul
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_etcd_consul_global_admiral: init_etcd_consul_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target aws_s3_bucket_object.etcd_consul_cloud_config \
	           -target module.etcd-consul.module.launch-configuration \
						 -target module.etcd-consul.module.auto-scaling-group \
						 -target module.etcd-consul_scale_up_policy \
						 -target module.etcd-consul_scale_down_policy \
						 -target aws_security_group_rule.sg-etcd-consul-ssh \
						 -target aws_security_group_rule.sg-etcd-consul-outgoing \
						 -target aws_security_group_rule.sg-etcd \
						 -target aws_security_group_rule.sg-fleet \
						 -target aws_security_group_rule.sg-consul-ui \
						 -target aws_security_group_rule.sg-consul-cluster \
						 -target module.etcd-consul;

refresh_etcd_consul_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target aws_s3_bucket_object.etcd_consul_cloud_config \
	              -target module.etcd-consul.module.launch-configuration \
								-target module.etcd-consul.module.auto-scaling-group \
								-target module.etcd-consul_scale_up_policy \
								-target module.etcd-consul_scale_down_policy \
								-target aws_security_group_rule.sg-etcd-consul-ssh \
								-target aws_security_group_rule.sg-etcd-consul-outgoing \
								-target aws_security_group_rule.sg-etcd \
								-target aws_security_group_rule.sg-fleet \
								-target aws_security_group_rule.sg-consul-ui \
								-target aws_security_group_rule.sg-consul-cluster \
								-target module.etcd-consul;

destroy_etcd_consul_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d etcd-consul; \
	$(TF_DESTROY)               -target module.etcd-consul \
								-target aws_security_group_rule.sg-etcd-consul-ssh \
								-target aws_security_group_rule.sg-etcd-consul-outgoing \
								-target aws_security_group_rule.sg-consul-cluster \
								-target aws_security_group_rule.sg-consul-ui \
								-target aws_security_group_rule.sg-etcd \
								-target aws_security_group_rule.sg-fleet \
								-target module.etcd-consul_scale_up_policy \
								-target module.etcd-consul_scale_down_policy \
								-target module.etcd-consul.module.auto-scaling-group \
								-target module.etcd-consul.module.launch-configuration \
								-target aws_s3_bucket_object.etcd_consul_cloud_config;

clean_etcd_consul_global_admiral: destroy_etcd_consul_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/etcd-consul.tf

init_etcd_consul_global_admiral: init_instance_pool_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/etcd-consul.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/etcd-consul* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/etcd-consul* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: etcd_consul_global_admiral destroy_etcd_consul_global_admiral refresh_etcd_consul_global_admiral plan_etcd_consul_global_admiral init_etcd_consul_global_admiral clean_etcd_consul_global_admiral