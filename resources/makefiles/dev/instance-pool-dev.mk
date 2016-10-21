instance_pool_dev: mysql_dev worker_dev

plan_instance_pool_dev: plan_mysql_dev plan_worker_dev

refresh_instance_pool_dev: refresh_mysql_dev refresh_worker_dev

destroy_instance_pool_dev: destroy_worker_dev destroy_mysql_dev

init_instance_pool_dev: init_dev
	cp -rf $(INFRA_DEV)/instance-pool/policy/assume-role-policy.json $(BUILD_DEV)/policy;
	cp -rf $(INFRA_DEV)/instance-pool/user-data/bootstrap* $(BUILD_DEV)/user-data;
	cp -rf $(INFRA_DEV)/instance-pool/scripts/download-registry-certificates.sh $(BUILD_DEV)/scripts;

.PHONY: instance_pool_dev destroy_instance_pool_dev refresh_instance_pool_dev plan_instance_pool_dev