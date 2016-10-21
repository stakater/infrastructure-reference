mysql_qa: plan_mysql_qa
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -c mysql-qa; \
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

plan_mysql_qa: init_mysql_qa
	cd $(BUILD_QA); \
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

refresh_mysql_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
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

destroy_mysql_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-qa-config -d mysql-qa; \
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
								-target aws_elb.mysql-qa \
								-target aws_elb.mysql-qa-internal;

clean_mysql_qa: destroy_mysql_qa
	rm -f $(BUILD_QA)/mysql.tf

init_mysql_qa: init_instance_pool_qa
		cp -rf $(INFRA_QA)/instance-pool/mysql.tf $(BUILD_QA);
		cp -rf $(INFRA_QA)/instance-pool/policy/mysql* $(BUILD_QA)/policy;
		cp -rf $(INFRA_QA)/instance-pool/user-data/mysql* $(BUILD_QA)/user-data;
		cd $(BUILD_QA); $(TF_GET);

.PHONY: mysql_qa destroy_mysql_qa refresh_mysql_qa plan_mysql_qa init_mysql_qa clean_mysql_qa