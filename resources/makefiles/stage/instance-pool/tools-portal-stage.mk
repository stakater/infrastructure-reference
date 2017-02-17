tools_portal_stage: plan_tools_portal_stage
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -c $(STACK_NAME)-stage-tools-portal; \
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

plan_tools_portal_stage: init_tools_portal_stage
	cd $(BUILD_STAGE); \
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

refresh_tools_portal_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
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

destroy_tools_portal_stage: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-stage-config -d $(STACK_NAME)-stage-tools-portal; \
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

clean_tools_portal_stage: destroy_tools_portal_stage
	rm -f $(BUILD_STAGE)/tools-portal.tf

init_tools_portal_stage: init_instance_pool_stage
		cp -rf $(INFRA_STAGE)/instance-pool/data/tools-portal/ $(BUILD_STAGE)/data;
		cp -rf $(INFRA_STAGE)/instance-pool/tools-portal.tf $(BUILD_STAGE);
		cp -rf $(INFRA_STAGE)/instance-pool/policy/tools-portal* $(BUILD_STAGE)/policy;
		cp -rf $(INFRA_STAGE)/instance-pool/user-data/tools-portal* $(BUILD_STAGE)/user-data;
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: tools_portal_stage destroy_tools_portal_stage refresh_tools_portal_stage plan_tools_portal_stage init_tools_portal_stage clean_tools_portal_stage