worker_dev: plan_worker_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c worker-dev; \
	$(TF_APPLY) -target aws_s3_bucket_object.worker-dev-cloud-config \
							-target module.worker-dev.module.launch-configuration \
							-target aws_security_group_rule.sg-worker-dev \
							-target aws_security_group_rule.sg-worker-dev-fleet \
							-target module.worker-dev.module.auto-scaling-group \
							-target module.worker-dev-scale-up-policy \
							-target module.worker-dev-scale-down-policy \
							-target module.worker-dev \
							-target aws_route53_record.worker-dev \
							-target aws_lb_cookie_stickiness_policy.worker-dev-elb-stickiness-policy \
							-target aws_security_group_rule.sg_worker_dev_registry \
							-target aws_security_group_rule.sg_worker_dev_etcd;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_worker_dev: init_worker_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target aws_s3_bucket_object.worker-dev-cloud-config \
						 -target module.worker-dev.module.launch-configuration \
						 -target aws_security_group_rule.sg-worker-dev \
						 -target aws_security_group_rule.sg-worker-dev-fleet \
						 -target module.worker-dev.module.auto-scaling-group \
						 -target module.worker-dev-scale-up-policy \
						 -target module.worker-dev-scale-down-policy \
						 -target module.worker-dev \
						 -target aws_route53_record.worker-dev \
						 -target aws_lb_cookie_stickiness_policy.worker-dev-elb-stickiness-policy \
						 -target aws_security_group_rule.sg_worker_dev_registry \
						 -target aws_security_group_rule.sg_worker_dev_etcd;

refresh_worker_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target aws_s3_bucket_object.worker-dev-cloud-config \
								-target module.worker-dev.module.launch-configuration \
								-target aws_security_group_rule.sg-worker-dev \
								-target aws_security_group_rule.sg-worker-dev-fleet \
								-target module.worker-dev.module.auto-scaling-group \
								-target module.worker-dev-scale-up-policy \
								-target module.worker-dev-scale-down-policy \
								-target module.worker-dev \
								-target aws_route53_record.worker-dev \
								-target aws_lb_cookie_stickiness_policy.worker-dev-elb-stickiness-policy \
								-target aws_security_group_rule.sg_worker_dev_registry \
								-target aws_security_group_rule.sg_worker_dev_etcd;

destroy_worker_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d worker-dev; \
	$(TF_DESTROY) -target aws_security_group_rule.sg_worker_dev_registry \
								-target aws_security_group_rule.sg_worker_dev_etcd \
								-target aws_lb_cookie_stickiness_policy.worker-dev-elb-stickiness-policy \
	              -target aws_route53_record.worker-dev \
								-target aws_security_group_rule.sg-worker-dev-fleet \
	              -target aws_security_group_rule.sg-worker-dev \
	              -target module.worker-dev \
								-target module.worker-dev-scale-up-policy \
								-target module.worker-dev-scale-down-policy \
								-target module.worker-dev.module.auto-scaling-group \
								-target module.worker-dev.module.launch-configuration \
								-target aws_s3_bucket_object.worker-dev-cloud-config;

clean_worker_dev: destroy_worker_dev
	rm -f $(BUILD_DEV)/worker-dev.tf

init_worker_dev: init_instance_pool_dev
		cp -rf $(INFRA_DEV)/instance-pool/worker-dev.tf $(BUILD_DEV);
		cp -rf $(INFRA_DEV)/instance-pool/policy/worker-dev* $(BUILD_DEV)/policy;
		cp -rf $(INFRA_DEV)/instance-pool/user-data/worker-dev* $(BUILD_DEV)/user-data;
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: worker_dev destroy_worker_dev refresh_worker_dev plan_worker_dev init_worker_dev clean_worker_dev