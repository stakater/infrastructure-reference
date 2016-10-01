worker_qa: plan_worker_qa
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -c worker-qa; \
	$(TF_APPLY) -target aws_s3_bucket_object.worker-cloud-config \
							-target module.worker.module.launch-configuration \
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

plan_worker_qa: init_worker_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target aws_s3_bucket_object.worker-cloud-config \
						 -target module.worker.module.launch-configuration \
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

refresh_worker_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target aws_s3_bucket_object.worker-cloud-config \
								-target module.worker.module.launch-configuration \
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

destroy_worker_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -d worker-qa; \
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
								-target module.worker.module.launch-configuration \
								-target aws_s3_bucket_object.worker-cloud-config;

clean_worker_qa: destroy_worker_qa
	rm -f $(BUILD_QA)/worker.tf

init_worker_qa: init_instance_pool_qa
		cp -rf $(INFRA_QA)/instance-pool/worker.tf $(BUILD_QA);
		cp -rf $(INFRA_QA)/instance-pool/policy/worker* $(BUILD_QA)/policy;
		cp -rf $(INFRA_QA)/instance-pool/user-data/worker* $(BUILD_QA)/user-data;
		cd $(BUILD_QA); $(TF_GET);

.PHONY: worker_qa destroy_worker_qa refresh_worker_qa plan_worker_qa init_worker_qa clean_worker_qa