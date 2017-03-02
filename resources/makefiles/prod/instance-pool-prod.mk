instance_pool_prod: consul_prod tools_portal_prod

plan_instance_pool_prod: plan_consul_prod plan_tools_portal_prod

refresh_instance_pool_prod: refresh_consul_prod refresh_tools_portal_prod

destroy_instance_pool_prod: destroy_mysql_prod destroy_tools_portal_prod

init_instance_pool_prod: init_prod
	cp -rf $(INFRA_PROD)/instance-pool/policy/assume-role-policy.json $(BUILD_PROD)/policy;
	cp -rf $(INFRA_PROD)/instance-pool/user-data/bootstrap* $(BUILD_PROD)/user-data;

.PHONY: instance_pool_prod destroy_instance_pool_prod refresh_instance_pool_prod plan_instance_pool_prod