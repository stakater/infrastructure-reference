gocd_global_admiral: plan_gocd_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c gocd; \
	$(TF_APPLY) -target aws_s3_bucket_object.gocd_cloud_config \
	            -target aws_s3_bucket_object.gocd_build_ami \
	            -target aws_s3_bucket_object.clone_deployment_application_code \
                -target aws_s3_bucket_object.gocd_build_docker_image \
                -target aws_s3_bucket_object.gocd_compile_code \
                -target aws_s3_bucket_object.gocd_deploy_to_cluster \
                -target aws_s3_bucket_object.gocd_deploy_to_prod \
                -target aws_s3_bucket_object.gocd_docker_cleanup \
                -target aws_s3_bucket_object.gocd_gocd_parameters \
                -target aws_s3_bucket_object.gocd_prod_deploy_params \
                -target aws_s3_bucket_object.gocd_read_parameter \
                -target aws_s3_bucket_object.gocd_rollback_deployment \
                -target aws_s3_bucket_object.gocd_switch_deployment_group \
                -target aws_s3_bucket_object.gocd_terraform_apply_changes \
                -target aws_s3_bucket_object.gocd_test \
                -target aws_s3_bucket_object.gocd_update_blue_green_deployment_groups \
                -target aws_s3_bucket_object.gocd_update_deployment_state \
                -target aws_s3_bucket_object.gocd_write_ami_parameters \
                -target aws_s3_bucket_object.gocd_write_terraform_variables \
                -target aws_s3_bucket_object.gocd_cruise_config \
                -target aws_s3_bucket_object.gocd_passwd \
                -target aws_s3_bucket_object.gocd_sudoers \
                -target module.gocd.module.launch-configuration \
                -target aws_security_group_rule.sg-gocd-ssh \
                -target aws_security_group_rule.sg-gocd-outgoing \
                -target aws_security_group_rule.sg-gocd-app \
                -target module.gocd.module.auto-scaling-group \
                -target module.gocd_scale_up_policy \
                -target module.gocd_scale_down_policy \
                -target module.gocd \
                -target aws_lb_cookie_stickiness_policy.gocd-elb-stickiness-policy;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_gocd_global_admiral: init_gocd_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target aws_s3_bucket_object.gocd_cloud_config \
               -target aws_s3_bucket_object.gocd_build_ami \
               -target aws_s3_bucket_object.clone_deployment_application_code \
               -target aws_s3_bucket_object.gocd_build_docker_image \
               -target aws_s3_bucket_object.gocd_compile_code \
               -target aws_s3_bucket_object.gocd_deploy_to_cluster \
               -target aws_s3_bucket_object.gocd_deploy_to_prod \
               -target aws_s3_bucket_object.gocd_docker_cleanup \
               -target aws_s3_bucket_object.gocd_gocd_parameters \
               -target aws_s3_bucket_object.gocd_prod_deploy_params \
               -target aws_s3_bucket_object.gocd_read_parameter \
               -target aws_s3_bucket_object.gocd_rollback_deployment \
               -target aws_s3_bucket_object.gocd_switch_deployment_group \
               -target aws_s3_bucket_object.gocd_terraform_apply_changes \
               -target aws_s3_bucket_object.gocd_test \
               -target aws_s3_bucket_object.gocd_update_blue_green_deployment_groups \
               -target aws_s3_bucket_object.gocd_update_deployment_state \
               -target aws_s3_bucket_object.gocd_write_ami_parameters \
               -target aws_s3_bucket_object.gocd_write_terraform_variables \
               -target aws_s3_bucket_object.gocd_cruise_config \
               -target aws_s3_bucket_object.gocd_passwd \
               -target aws_s3_bucket_object.gocd_sudoers \
               -target module.gocd.module.launch-configuration \
               -target module.gocd.module.auto-scaling-group \
               -target module.gocd_scale_up_policy \
               -target module.gocd_scale_down_policy \
               -target aws_security_group_rule.sg-gocd-ssh \
               -target aws_security_group_rule.sg-gocd-outgoing \
               -target aws_security_group_rule.sg-gocd-app \
               -target module.gocd \
               -target aws_lb_cookie_stickiness_policy.gocd-elb-stickiness-policy;

refresh_gocd_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target aws_s3_bucket_object.gocd_cloud_config \
	            	-target aws_s3_bucket_object.gocd_build_ami \
	            	-target aws_s3_bucket_object.clone_deployment_application_code \
                    -target aws_s3_bucket_object.gocd_build_docker_image \
                    -target aws_s3_bucket_object.gocd_compile_code \
                    -target aws_s3_bucket_object.gocd_deploy_to_cluster \
                    -target aws_s3_bucket_object.gocd_deploy_to_prod \
                    -target aws_s3_bucket_object.gocd_docker_cleanup \
                    -target aws_s3_bucket_object.gocd_gocd_parameters \
                    -target aws_s3_bucket_object.gocd_prod_deploy_params \
                    -target aws_s3_bucket_object.gocd_read_parameter \
                    -target aws_s3_bucket_object.gocd_rollback_deployment \
                    -target aws_s3_bucket_object.gocd_switch_deployment_group \
                    -target aws_s3_bucket_object.gocd_terraform_apply_changes \
                    -target aws_s3_bucket_object.gocd_test \
                    -target aws_s3_bucket_object.gocd_update_blue_green_deployment_groups \
                    -target aws_s3_bucket_object.gocd_update_deployment_state \
                    -target aws_s3_bucket_object.gocd_write_ami_parameters \
                    -target aws_s3_bucket_object.gocd_write_terraform_variables \
                    -target aws_s3_bucket_object.gocd_cruise_config \
                    -target aws_s3_bucket_object.gocd_passwd \
                    -target aws_s3_bucket_object.gocd_sudoers \
                    -target module.gocd.module.launch-configuration \
                    -target module.gocd.module.auto-scaling-group \
                    -target module.gocd_scale_up_policy \
                    -target module.gocd_scale_down_policy \
                    -target aws_security_group_rule.sg-gocd-ssh \
                    -target aws_security_group_rule.sg-gocd-outgoing \
                    -target aws_security_group_rule.sg-gocd-app \
                    -target module.gocd \
                    -target aws_lb_cookie_stickiness_policy.gocd-elb-stickiness-policy;

destroy_gocd_global_admiral: init_gocd_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d gocd; \
	$(TF_DESTROY) -target aws_lb_cookie_stickiness_policy.gocd-elb-stickiness-policy \
	              -target module.gocd \
                  -target aws_security_group_rule.sg-gocd-ssh \
                  -target aws_security_group_rule.sg-gocd-outgoing \
                  -target aws_security_group_rule.sg-gocd-app \
                  -target module.gocd_scale_up_policy \
                  -target module.gocd_scale_down_policy \
                  -target module.gocd.module.auto-scaling-group \
                  -target module.gocd.module.launch-configuration \
                  -target aws_s3_bucket_object.gocd_cloud_config \
		          		-target aws_s3_bucket_object.gocd_build_ami \
		          		-target aws_s3_bucket_object.clone_deployment_application_code \
                  -target aws_s3_bucket_object.gocd_build_docker_image \
                  -target aws_s3_bucket_object.gocd_compile_code \
                  -target aws_s3_bucket_object.gocd_deploy_to_prod \
                  -target aws_s3_bucket_object.gocd_deploy_to_cluster \
                  -target aws_s3_bucket_object.gocd_docker_cleanup \
                  -target aws_s3_bucket_object.gocd_prod_deploy_params \
                  -target aws_s3_bucket_object.gocd_gocd_parameters \
                  -target aws_s3_bucket_object.gocd_read_parameter \
                  -target aws_s3_bucket_object.gocd_write_ami_parameters \
                  -target aws_s3_bucket_object.gocd_rollback_deployment \
                  -target aws_s3_bucket_object.gocd_switch_deployment_group \
                  -target aws_s3_bucket_object.gocd_terraform_apply_changes \
                  -target aws_s3_bucket_object.gocd_test \
                  -target aws_s3_bucket_object.gocd_update_blue_green_deployment_groups \
                  -target aws_s3_bucket_object.gocd_update_deployment_state \
                  -target aws_s3_bucket_object.gocd_write_terraform_variables \
                  -target aws_s3_bucket_object.gocd_cruise_config \
                  -target aws_s3_bucket_object.gocd_passwd \
                  -target aws_s3_bucket_object.gocd_sudoers;

clean_gocd_global_admiral: destroy_gocd_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/gocd.tf

init_gocd_global_admiral: init_instance_pool_global_admiral
		mkdir -p $(BUILD_GLOBAL_ADMIRAL)/data/gocd; \
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/gocd.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/gocd* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/scripts/gocd* $(BUILD_GLOBAL_ADMIRAL)/scripts;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/gocd* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/data/gocd/* $(BUILD_GLOBAL_ADMIRAL)/data/gocd;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: gocd_global_admiral destroy_gocd_global_admiral refresh_gocd_global_admiral plan_gocd_global_admiral init_gocd_global_admiral clean_gocd_global_admiral
