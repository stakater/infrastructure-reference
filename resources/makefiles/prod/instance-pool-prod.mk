instance_pool_prod: worker_prod

plan_instance_pool_prod: plan_worker_prod

refresh_instance_pool_prod: refresh_worker_prod

destroy_instance_pool_prod: destroy_worker_prod

init_instance_pool_prod: init_prod
	cp -rf $(INFRA_PROD)/instance-pool/policy/assume-role-policy.json $(BUILD_PROD)/policy;

.PHONY: instance_pool_prod destroy_instance_pool_prod refresh_instance_pool_prod plan_instance_pool_prod