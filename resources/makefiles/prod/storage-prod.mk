storage_prod: plan_storage_prod
	cd $(BUILD_PROD); \
	$(TF_APPLY)	-target module.config-bucket \
				-target module.cloudinit-bucket \
				-target module.maintenance-page-bucket \
				-target aws_s3_bucket_object.upload-maintenance-index-page \
				-target aws_s3_bucket_object.upload-maintenance-error-page;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_storage_prod: init_storage_prod
	cd $(BUILD_PROD); \
	$(TF_PLAN)  -target module.config-bucket \
				-target module.cloudinit-bucket \
				-target module.maintenance-page-bucket \
				-target aws_s3_bucket_object.upload-maintenance-index-page \
				-target aws_s3_bucket_object.upload-maintenance-error-page;

refresh_storage_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_REFRESH) -target module.config-bucket \
				  -target module.cloudinit-bucket \
				  -target module.maintenance-page-bucket \
				  -target aws_s3_bucket_object.upload-maintenance-index-page \
				  -target aws_s3_bucket_object.upload-maintenance-error-page;

destroy_storage_prod: | $(TF_PROVIDER_PROD) pull_prod_state
	cd $(BUILD_PROD); \
	$(TF_DESTROY) -target module.config-bucket \
				  -target module.cloudinit-bucket \
				  -target aws_s3_bucket_object.upload-maintenance-index-page \
				  -target aws_s3_bucket_object.upload-maintenance-error-page \
				  -target module.maintenance-page-bucket;

clean_storage_prod: destroy_storage_prod
	rm -f $(BUILD_PROD)/storage.tf

init_storage_prod: init_prod
		mkdir -p $(BUILD_PROD)/data;
		mkdir -p $(BUILD_PROD)/policy;
		cp -rf $(INFRA_PROD)/storage/storage.tf $(BUILD_PROD);
		cp -rf $(INFRA_PROD)/storage/data/* $(BUILD_PROD)/data;
		cp -rf $(INFRA_PROD)/storage/policy/* $(BUILD_PROD)/policy;
		cd $(BUILD_PROD); $(TF_GET);

.PHONY: storage_prod destroy_storage_prod refresh_storage_prod plan_storage_prod init_storage_prod clean_storage_prod