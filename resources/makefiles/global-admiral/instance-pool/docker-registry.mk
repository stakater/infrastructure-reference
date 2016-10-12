docker_registry_global_admiral: plan_docker_registry_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -c docker-registry; \
	$(TF_APPLY) -target aws_s3_bucket_object.docker_registry_cloud_config \
	            -target aws_s3_bucket_object.docker_registry_upload_script \
							-target module.docker-registry.module.launch-configuration \
							-target aws_security_group_rule.sg-docker-registry-ssh \
							-target aws_security_group_rule.sg-docker-registry-outgoing \
							-target aws_security_group_rule.sg-docker-registry-app \
							-target module.docker-registry.module.auto-scaling-group \
							-target module.docker-registry_scale_up_policy \
							-target module.docker-registry_scale_down_policy \
							-target module.docker-registry \
							-target aws_route53_record.docker-registry;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_docker_registry_global_admiral: init_docker_registry_global_admiral
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_PLAN) -target aws_s3_bucket_object.docker_registry_cloud_config \
						 -target aws_s3_bucket_object.docker_registry_upload_scripts \
						 -target module.docker-registry.module.launch-configuration \
						 -target module.docker-registry.module.auto-scaling-group \
						 -target module.docker-registry_scale_up_policy \
						 -target module.docker-registry_scale_down_policy \
						 -target aws_security_group_rule.sg-docker-registry-ssh \
						 -target aws_security_group_rule.sg-docker-registry-outgoing \
						 -target aws_security_group_rule.sg-docker-registry-app \
						 -target module.docker-registry \
						 -target aws_route53_record.docker-registry;

refresh_docker_registrys_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(TF_REFRESH) -target aws_s3_bucket_object.docker_registry_cloud_config \
	            	-target aws_s3_bucket_object.docker_registry_upload_script \
								-target module.docker-registry.module.launch-configuration \
								-target module.docker-registry.module.auto-scaling-group \
								-target module.docker-registry_scale_up_policy \
								-target module.docker-registry_scale_down_policy \
								-target aws_security_group_rule.sg-docker-registry-ssh \
								-target aws_security_group_rule.sg-docker-registry-outgoing \
								-target aws_security_group_rule.sg-docker-registry-app \
								-target module.docker-registry \
								-target aws_route53_record.docker-registry;

destroy_docker_registry_global_admiral: | $(TF_PROVIDER_GLOBAL_ADMIRAL) pull_global_admiral_state
	cd $(BUILD_GLOBAL_ADMIRAL); \
	$(SCRIPTS)/aws-keypair.sh -b $(STACK_NAME)-global-admiral-config -d docker-registry; \
	$(TF_DESTROY) -target aws_route53_record.docker-registry \
								-target aws_security_group_rule.sg-docker-registry-ssh \
								-target aws_security_group_rule.sg-docker-registry-outgoing \
								-target aws_security_group_rule.sg-docker-registry-app \
	              -target module.docker-registry \
								-target module.docker-registry_scale_up_policy \
								-target module.docker-registry_scale_down_policy \
								-target module.docker-registry.module.auto-scaling-group \
								-target module.docker-registry.module.launch-configuration \
								-target aws_s3_bucket_object.docker_registry_cloud_config \
		            -target aws_s3_bucket_object.docker_registry_upload_script \
								-target aws_security_group.docker-registry-sg-elb \
								-target aws_elb.docker-registry-elb;

clean_docker_registry_global_admiral: destroy_docker_registry_global_admiral
	rm -f $(BUILD_GLOBAL_ADMIRAL)/docker-registry.tf

init_docker_registry_global_admiral: init_instance_pool_global_admiral
		mkdir -p $(BUILD_GLOBAL_ADMIRAL)/data/docker-registry; \
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/docker-registry.tf $(BUILD_GLOBAL_ADMIRAL);
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/policy/docker-registry* $(BUILD_GLOBAL_ADMIRAL)/policy;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/scripts/docker-registry* $(BUILD_GLOBAL_ADMIRAL)/scripts;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/user-data/docker-registry* $(BUILD_GLOBAL_ADMIRAL)/user-data;
		cp -rf $(INFRA_GLOBAL_ADMIRAL)/instance-pool/data/docker-registry/* $(BUILD_GLOBAL_ADMIRAL)/data/docker-registry;
		cd $(BUILD_GLOBAL_ADMIRAL); $(TF_GET);

.PHONY: docker_registry_global_admiral destroy_docker_registry_global_admiral refresh_docker_registry_global_admiral plan_docker_registry_global_admiral init_docker_registry_global_admiral clean_docker-registry_global_admiral