worker_prod: plan_worker_prod
	cd $(BUILD_PROD); \
	export TF_VAR_prod_ami=ami-9cc015fc; \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -c worker-prod; \
	$(TF_APPLY) -target module.worker.module.launch-configuration \
							-target aws_security_group_rule.sg-worker \
							-target aws_security_group_rule.sg-worker-fleet \
							-target module.worker.module.auto-scaling-group \
							-target module.worker-scale-up-policy \
							-target module.worker-scale-down-policy \
							-target module.worker \
							-target aws_route53_record.worker \
							-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
							-target aws_security_group_rule.sg-worker-registry \
							-target aws_security_group_rule.sg-worker-etcd;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_worker_prod: init_worker_prod
	cd $(BUILD_PROD); \
	export TF_VAR_prod_ami=ami-9cc015fc; \
	$(TF_PLAN) -target module.worker.module.launch-configuration \
						 -target aws_security_group_rule.sg-worker \
						 -target aws_security_group_rule.sg-worker-fleet \
						 -target module.worker.module.auto-scaling-group \
						 -target module.worker-scale-up-policy \
						 -target module.worker-scale-down-policy \
						 -target module.worker \
						 -target aws_route53_record.worker \
						 -target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
						 -target aws_security_group_rule.sg-worker-registry \
						 -target aws_security_group_rule.sg-worker-etcd;

refresh_worker_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.worker.module.launch-configuration \
								-target aws_security_group_rule.sg-worker \
								-target aws_security_group_rule.sg-worker-fleet \
								-target module.worker.module.auto-scaling-group \
								-target module.worker-scale-up-policy \
								-target module.worker-scale-down-policy \
								-target module.worker \
								-target aws_route53_record.worker \
								-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
								-target aws_security_group_rule.sg-worker-registry \
								-target aws_security_group_rule.sg-worker-etcd;

destroy_worker_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -d worker-prod; \
	$(TF_DESTROY) -target aws_security_group_rule.sg-worker-registry \
								-target aws_security_group_rule.sg-worker-etcd \
								-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
	              -target aws_route53_record.worker \
								-target aws_security_group_rule.sg-worker-fleet \
	              -target aws_security_group_rule.sg-worker \
	              -target module.worker \
								-target module.worker-scale-up-policy \
								-target module.worker-scale-down-policy \
								-target module.worker.module.auto-scaling-group \
								-target module.worker.module.launch-configuration;

clean_worker_prod: destroy_worker_prod
	rm -f $(BUILD_PROD)/worker.tf

init_worker_prod: init_instance_pool_prod
		cp -rf $(INFRA_PROD)/instance-pool/worker.tf $(BUILD_PROD);
		cp -rf $(INFRA_PROD)/instance-pool/policy/worker* $(BUILD_PROD)/policy;
		cp -rf $(INFRA_PROD)/instance-pool/*.tfvars $(BUILD_PROD);
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: worker_prod destroy_worker_prod refresh_worker_prod plan_worker_prod init_worker_prod clean_worker_prod