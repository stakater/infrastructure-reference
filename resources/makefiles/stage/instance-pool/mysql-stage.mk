mysql_stage: plan_mysql_stage
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -c mysql-stage; \
	$(TF_APPLY) -target aws_s3_bucket_object.mysql-cloud-config \
							-target module.mysql.module.launch-configuration \
							-target module.mysql.module.auto-scaling-group \
							-target module.mysql-scale-up-policy \
							-target module.mysql-scale-down-policy \
							-target module.mysql \
							-target aws_route53_record.mysql-internal \
							-target aws_security_group_rule.sg-mysql-ssh \
							-target aws_security_group_rule.sg-mysql-outgoing \
							-target aws_security_group_rule.sg-mysql-app;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_mysql_stage: init_mysql_stage
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target aws_s3_bucket_object.mysql-cloud-config \
						 -target module.mysql.module.launch-configuration \
						 -target module.mysql.module.auto-scaling-group \
						 -target module.mysql-scale-up-policy \
						 -target module.mysql-scale-down-policy \
						 -target module.mysql \
						 -target aws_route53_record.mysql \
						 -target aws_route53_record.mysql-internal \
						 -target aws_security_group_rule.sg-mysql-ssh \
						 -target aws_security_group_rule.sg-mysql-outgoing \
						 -target aws_security_group_rule.sg-mysql-app;

refresh_mysql_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_REFRESH) -target aws_s3_bucket_object.mysql-cloud-config \
								-target module.mysql.module.launch-configuration \
								-target module.mysql.module.auto-scaling-group \
								-target module.mysql-scale-up-policy \
								-target module.mysql-scale-down-policy \
								-target module.mysql \
								-target aws_route53_record.mysql \
								-target aws_route53_record.mysql-internal \
								-target aws_security_group_rule.sg-mysql-ssh \
								-target aws_security_group_rule.sg-mysql-outgoing \
								-target aws_security_group_rule.sg-mysql-app;

destroy_mysql_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -d mysql-stage; \
	$(TF_DESTROY) -target aws_security_group_rule.sg-mysql-ssh \
								-target aws_security_group_rule.sg-mysql-outgoing \
								-target aws_security_group_rule.sg-mysql-app \
								-target aws_route53_record.mysql-internal \
	              -target aws_route53_record.mysql \
	              -target module.mysql \
								-target module.mysql-scale-up-policy \
								-target module.mysql-scale-down-policy \
								-target module.mysql.module.auto-scaling-group \
								-target module.mysql.module.launch-configuration \
								-target aws_s3_bucket_object.mysql-cloud-config \
								-target aws_security_group.mysql-sg-elb \
								-target aws_elb.mysql-stage \
								-target aws_elb.mysql-stage-internal;

clean_mysql_stage: destroy_mysql_stage
	rm -f $(BUILD_STAGE)/mysql.tf

init_mysql_stage: init_instance_pool_stage
		cp -rf $(INFRA_STAGE)/instance-pool/mysql.tf $(BUILD_STAGE);
		cp -rf $(INFRA_STAGE)/instance-pool/policy/mysql* $(BUILD_STAGE)/policy;
		cp -rf $(INFRA_STAGE)/instance-pool/user-data/mysql* $(BUILD_STAGE)/user-data;
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: mysql_stage destroy_mysql_stage refresh_mysql_stage plan_mysql_stage init_mysql_stage clean_mysql_stage