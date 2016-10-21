instance_pool_qa: worker_qa mysql_qa

plan_instance_pool_qa: plan_mysql_qa plan_worker_qa

refresh_instance_pool_qa: refresh_mysql_qa refresh_worker_qa

destroy_instance_pool_qa: destroy_worker_qa destroy_mysql_qa

init_instance_pool_qa: init_qa
	cp -rf $(INFRA_QA)/instance-pool/policy/assume-role-policy.json $(BUILD_QA)/policy;
	cp -rf $(INFRA_QA)/instance-pool/user-data/bootstrap* $(BUILD_QA)/user-data;
	cp -rf $(INFRA_QA)/instance-pool/scripts/download-registry-certificates.sh $(BUILD_QA)/scripts;

.PHONY: instance_pool_qa destroy_instance_pool_qa refresh_instance_pool_qa plan_instance_pool_qa