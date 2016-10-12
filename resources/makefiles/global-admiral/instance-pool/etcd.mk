etcd_global_admiral: plan_etcd_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c etcd; \
	$(TF_APPLY) -target aws_s3_bucket_object.etcd_cloud_config \
	            -target module.etcd.module.launch-configuration \
							-target module.etcd.module.auto-scaling-group \
							-target module.etcd_scale_up_policy \
							-target module.etcd_scale_down_policy \
							-target aws_security_group_rule.sg-etcd-ssh \
							-target aws_security_group_rule.sg-etcd-outgoing \
							-target aws_security_group_rule.sg-etcd \
							-target aws_security_group_rule.sg-fleet \
							-target module.etcd \
							-target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_etcd_global_admiral: init_etcd_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target aws_s3_bucket_object.etcd_cloud_config \
	           -target module.etcd.module.launch-configuration \
						 -target module.etcd.module.auto-scaling-group \
						 -target module.etcd_scale_up_policy \
						 -target module.etcd_scale_down_policy \
						 -target aws_security_group_rule.sg-etcd-ssh \
						 -target aws_security_group_rule.sg-etcd-outgoing \
						 -target aws_security_group_rule.sg-etcd \
						 -target aws_security_group_rule.sg-fleet \
						 -target module.etcd \
						 -target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;

refresh_etcd_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target aws_s3_bucket_object.etcd_cloud_config \
	              -target module.etcd.module.launch-configuration \
								-target module.etcd.module.auto-scaling-group \
								-target module.etcd_scale_up_policy \
								-target module.etcd_scale_down_policy \
								-target aws_security_group_rule.sg-etcd-ssh \
								-target aws_security_group_rule.sg-etcd-outgoing \
								-target aws_security_group_rule.sg-etcd \
								-target aws_security_group_rule.sg-fleet \
								-target module.etcd \
								-target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;

destroy_etcd_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d etcd; \
	$(TF_DESTROY) -target aws_lb_cookie_stickiness_policy.elb_stickiness_policy \
	              -target module.etcd \
								-target aws_security_group_rule.sg-etcd-ssh \
								-target aws_security_group_rule.sg-etcd-outgoing \
								-target aws_security_group_rule.sg-etcd \
								-target aws_security_group_rule.sg-fleet \
								-target module.etcd_scale_up_policy \
								-target module.etcd_scale_down_policy \
								-target module.etcd.module.auto-scaling-group \
								-target module.etcd.module.launch-configuration \
								-target aws_s3_bucket_object.etcd_cloud_config;

clean_etcd_global_admiral: destroy_etcd_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/etcd.tf

init_etcd_global_admiral: init_instance_pool_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/etcd.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/etcd* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/etcd* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: etcd_global_admiral destroy_etcd_global_admiral refresh_etcd_global_admiral plan_etcd_global_admiral init_etcd_global_admiral clean_etcd_global_admiral