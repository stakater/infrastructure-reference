instance_pool_global_admiral: plan_instance_pool_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c etcd; \
	$(TF_APPLY) -target module.etcd.module.launch-configuration \
							-target module.etcd.module.auto-scaling-group \
							-target module.etcd_scale_up_policy \
							-target module.etcd_scale_down_policy \
							-target aws_security_group_rule.sg_etcd_8080 \
							-target module.etcd \
							-target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_instance_pool_global_admiral: init_instance_pool_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target module.etcd.module.launch-configuration \
						 -target module.etcd.module.auto-scaling-group \
						 -target module.etcd_scale_up_policy \
						 -target module.etcd_scale_down_policy \
						 -target aws_security_group_rule.sg_etcd_8080 \
						 -target module.etcd \
						 -target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;

refresh_instance_pool_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target module.etcd.module.launch-configuration \
								-target module.etcd.module.auto-scaling-group \
								-target module.etcd_scale_up_policy \
								-target module.etcd_scale_down_policy \
								-target aws_security_group_rule.sg_etcd_8080 \
								-target module.etcd \
								-target aws_lb_cookie_stickiness_policy.elb_stickiness_policy;

destroy_instance_pool_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d etcd; \
	$(TF_DESTROY) -target aws_lb_cookie_stickiness_policy.elb_stickiness_policy \
	              -target module.etcd \
	              -target aws_security_group_rule.sg_etcd_8080 \
								-target module.etcd_scale_up_policy \
								-target module.etcd_scale_down_policy \
								-target module.etcd.module.auto-scaling-group \
								-target module.etcd.module.launch-configuration;

clean_instance_pool_global_admiral: destroy_instance_pool_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/instance-pool.tf

init_instance_pool_global_admiral: init_global_admiral
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/*.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: instance_pool_global_admiral destroy_instance_pool_global_admiral refresh_instance_pool_global_admiral plan_instance_pool_global_admiral init_instance_pool_global_admiral clean_instance_pool_global_admiral