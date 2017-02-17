instance_pool_stage: consul_stage mysql_stage

plan_instance_pool_stage: plan_consul_stage plan_mysql_stage

refresh_instance_pool_stage: refresh_consul_stage refresh_mysql_stage

destroy_instance_pool_stage: destroy_mysql_stage destroy_consul_stage

init_instance_pool_stage: init_stage
	cp -rf $(INFRA_STAGE)/instance-pool/policy/assume-role-policy.json $(BUILD_STAGE)/policy;
	cp -rf $(INFRA_STAGE)/instance-pool/user-data/bootstrap* $(BUILD_STAGE)/user-data;

.PHONY: instance_pool_stage destroy_instance_pool_stage refresh_instance_pool_stage plan_instance_pool_stage