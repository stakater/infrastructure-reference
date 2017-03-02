tools_portal_prod: plan_tools_portal_prod
	cd $(BUILD_PROD); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -c $(STACK_NAME)-prod-tools-portal; \
	$(TF_APPLY) -target aws_s3_bucket_object.tools-portal-cloud-config \
				-target aws_s3_bucket_object.tools-portal-nginx-config-tmpl \
	            -target module.tools-portal.module.iam \
	            -target module.tools-portal.module.solo-instance \
				-target module.tools-portal.module.elastic-ip\
				-target aws_security_group_rule.sg-tools-portal-ssh \
				-target aws_security_group_rule.sg-tools-portal-outgoing \
				-target aws_security_group_rule.sg-tools-portal-consul \
			  	-target aws_security_group_rule.sg-tools-portal-consul-8500 \
				-target aws_security_group_rule.sg-tools-portal-80 \
				-target aws_route53_record.tools-portal \
				-target module.tools-portal;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_tools_portal_prod: init_tools_portal_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target aws_s3_bucket_object.tools-portal-cloud-config \
			   -target aws_s3_bucket_object.tools-portal-nginx-config-tmpl \
	           -target module.tools-portal.module.iam \
	           -target module.tools-portal.module.solo-instance \
			   -target module.tools-portal.module.elastic-ip\
			   -target aws_security_group_rule.sg-tools-portal-ssh \
			   -target aws_security_group_rule.sg-tools-portal-outgoing \
			   -target aws_security_group_rule.sg-tools-portal-consul \
			   -target aws_security_group_rule.sg-tools-portal-consul-8500 \
			   -target aws_security_group_rule.sg-tools-portal-80 \
			   -target module.tools-portal;

refresh_tools_portal_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target aws_s3_bucket_object.tools-portal-cloud-config \
				  -target aws_s3_bucket_object.tools-portal-nginx-config-tmpl \
	              -target module.tools-portal.module.iam \
				  -target module.tools-portal.module.solo-instance \
				  -target module.tools-portal.module.elastic-ip\
				  -target aws_security_group_rule.sg-tools-portal-ssh \
				  -target aws_security_group_rule.sg-tools-portal-outgoing \
				  -target aws_security_group_rule.sg-tools-portal-consul \
				  -target aws_security_group_rule.sg-tools-portal-consul-8500 \
				  -target aws_security_group_rule.sg-tools-portal-80 \
				  -target aws_route53_record.tools-portal \
				  -target aws_elb.tools-portal-elb \
				  -target aws_security_group.tools-portal-sg-elb \
				  -target module.tools-portal;

destroy_tools_portal_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-prod-config -d $(STACK_NAME)-prod-tools-portal; \
	$(TF_DESTROY) -target module.tools-portal \
				  -target aws_security_group_rule.sg-tools-portal-ssh \
				  -target aws_security_group_rule.sg-tools-portal-outgoing \
				  -target aws_security_group_rule.sg-tools-portal-consul \
				  -target aws_security_group_rule.sg-tools-portal-consul-8500 \
				  -target aws_security_group_rule.sg-tools-portal-80 \
				  -target module.tools-portal.module.elastic-ip\
				  -target module.tools-portal.module.solo-instance \
	              -target module.tools-portal.module.iam \
			      -target aws_route53_record.tools-portal \
				  -target aws_s3_bucket_object.tools-portal-nginx-config-tmpl \
				  -target aws_s3_bucket_object.tools-portal-cloud-config;

clean_tools_portal_prod: destroy_tools_portal_prod
	rm -f $(BUILD_PROD)/tools-portal.tf

init_tools_portal_prod: init_instance_pool_prod
		cp -rf $(INFRA_PROD)/instance-pool/data/tools-portal/ $(BUILD_PROD)/data;
		cp -rf $(INFRA_PROD)/instance-pool/tools-portal.tf $(BUILD_PROD);
		cp -rf $(INFRA_PROD)/instance-pool/policy/tools-portal* $(BUILD_PROD)/policy;
		cp -rf $(INFRA_PROD)/instance-pool/user-data/tools-portal* $(BUILD_PROD)/user-data;
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: tools_portal_prod destroy_tools_portal_prod refresh_tools_portal_prod plan_tools_portal_prod init_tools_portal_prod clean_tools_portal_prod