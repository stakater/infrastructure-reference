prod_user_data: plan_prod_user_data
	cd $(BUILD_PROD); \
	$(TF_APPLY) -target aws_s3_bucket_object.prod-cloud-config;

plan_prod_user_data: init_prod_user_data
	cd $(BUILD_PROD); \
	$(TF_PLAN) -target aws_s3_bucket_object.prod-cloud-config;

refresh_prod_user_data: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target aws_s3_bucket_object.prod-cloud-config;

destroy_prod_user_data: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_DESTROY)	-target aws_s3_bucket_object.prod-cloud-config;

clean_prod_user_data: destroy_prod_user_data
	rm -f $(BUILD_PROD)/prod-user-data.tf

init_prod_user_data: init_prod
		cp -rf $(INFRA_PROD)/instance-pool/prod-user-data.tf $(BUILD_PROD);
		cp -rf $(INFRA_PROD)/instance-pool/user-data/prod* $(BUILD_PROD)/user-data;
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: prod_user_data destroy_prod_user_data refresh_prod_user_data plan_prod_user_data init_prod_user_data clean_prod_user_data