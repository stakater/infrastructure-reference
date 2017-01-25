worker_dev: plan_worker_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c worker-dev; \
	$(TF_APPLY) -target aws_s3_bucket_object.worker-cloud-config \
							-target aws_s3_bucket_object.filebeat-config-tmpl \
							-target module.worker.module.launch-configuration \
							-target module.worker.module.auto-scaling-group \
							-target module.worker-scale-up-policy \
							-target module.worker-scale-down-policy \
							-target module.worker \
							-target aws_route53_record.worker \
							-target aws_route53_record.worker-internal \
							-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
							-target aws_security_group_rule.sg-worker-ssh \
							-target aws_security_group_rule.sg-worker-outgoing \
							-target aws_security_group_rule.sg-worker-app \
							-target aws_security_group_rule.sg-worker-fleet \
							-target aws_security_group_rule.sg-worker-registry \
							-target aws_security_group_rule.sg-worker-etcd;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_worker_dev: init_worker_dev
	cd $(BUILD_DEV); \
	$(TF_PLAN) -target aws_s3_bucket_object.worker-cloud-config \
						 -target aws_s3_bucket_object.filebeat-config-tmpl \
						 -target module.worker.module.launch-configuration \
						 -target module.worker.module.auto-scaling-group \
						 -target module.worker-scale-up-policy \
						 -target module.worker-scale-down-policy \
						 -target module.worker \
						 -target aws_route53_record.worker \
						 -target aws_route53_record.worker-internal \
						 -target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
						 -target aws_security_group_rule.sg-worker-ssh \
						 -target aws_security_group_rule.sg-worker-outgoing \
						 -target aws_security_group_rule.sg-worker-app \
						 -target aws_security_group_rule.sg-worker-fleet \
						 -target aws_security_group_rule.sg-worker-registry \
						 -target aws_security_group_rule.sg-worker-etcd;

refresh_worker_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(TF_REFRESH) -target aws_s3_bucket_object.worker-cloud-config \
								-target aws_s3_bucket_object.filebeat-config-tmpl \
								-target module.worker.module.launch-configuration \
								-target module.worker.module.auto-scaling-group \
								-target module.worker-scale-up-policy \
								-target module.worker-scale-down-policy \
								-target module.worker \
								-target aws_route53_record.worker \
								-target aws_route53_record.worker-internal \
								-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
								-target aws_security_group_rule.sg-worker-ssh \
								-target aws_security_group_rule.sg-worker-outgoing \
								-target aws_security_group_rule.sg-worker-app \
								-target aws_security_group_rule.sg-worker-fleet \
								-target aws_security_group_rule.sg-worker-registry \
								-target aws_security_group_rule.sg-worker-etcd;

destroy_worker_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d worker-dev; \
	$(TF_DESTROY) -target aws_security_group_rule.sg-worker-registry \
								-target aws_security_group_rule.sg-worker-etcd \
								-target aws_security_group_rule.sg-worker-ssh \
								-target aws_security_group_rule.sg-worker-outgoing \
								-target aws_security_group_rule.sg-worker-app \
								-target aws_security_group_rule.sg-worker-fleet \
								-target aws_lb_cookie_stickiness_policy.worker-elb-stickiness-policy \
								-target aws_route53_record.worker-internal \
	              -target aws_route53_record.worker \
	              -target module.worker \
								-target module.worker-scale-up-policy \
								-target module.worker-scale-down-policy \
								-target module.worker.module.auto-scaling-group \
								-target module.worker.module.launch-configuration \
								-target aws_s3_bucket_object.worker-cloud-config \
								-target aws_s3_bucket_object.filebeat-config-tmpl \
								-target aws_security_group.worker-sg-elb \
								-target aws_elb.worker-dev \
								-target aws_elb.worker-dev-internal;

clean_worker_dev: destroy_worker_dev
	rm -f $(BUILD_DEV)/worker.tf

init_worker_dev: init_instance_pool_dev
		cp -rf $(INFRA_DEV)/instance-pool/worker.tf $(BUILD_DEV);
		cp -rf $(INFRA_DEV)/instance-pool/policy/worker* $(BUILD_DEV)/policy;
		cp -rf $(INFRA_DEV)/instance-pool/user-data/worker* $(BUILD_DEV)/user-data;
		cp -rf $(INFRA_DEV)/instance-pool/data/worker/* $(BUILD_DEV)/data/worker;
		cp -rf $(INFRA_DEV)/instance-pool/scripts/download-filebeat-template.sh.tmpl $(BUILD_DEV)/scripts;
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: worker_dev destroy_worker_dev refresh_worker_dev plan_worker_dev init_worker_dev clean_worker_dev