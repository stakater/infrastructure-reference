mysql_dev: plan_mysql_dev
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -c mysql-dev; \
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

plan_mysql_dev: init_mysql_dev
	cd $(BUILD_DEV); \
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

refresh_mysql_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
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

destroy_mysql_dev: | $(TF_PROVIDER_DEV) pull_dev_state
	cd $(BUILD_DEV); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-dev-config -d mysql-dev; \
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
								-target aws_elb.mysql-dev \
								-target aws_elb.mysql-dev-internal;

clean_mysql_dev: destroy_mysql_dev
	rm -f $(BUILD_DEV)/mysql.tf

init_mysql_dev: init_instance_pool_dev
		cp -rf $(INFRA_DEV)/instance-pool/mysql.tf $(BUILD_DEV);
		cp -rf $(INFRA_DEV)/instance-pool/policy/mysql* $(BUILD_DEV)/policy;
		cp -rf $(INFRA_DEV)/instance-pool/user-data/mysql* $(BUILD_DEV)/user-data;
		cd $(BUILD_DEV); $(TF_GET);

.PHONY: mysql_dev destroy_mysql_dev refresh_mysql_dev plan_mysql_dev init_mysql_dev clean_mysql_dev