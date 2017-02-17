stage_user_data: plan_stage_user_data
	cd $(BUILD_STAGE); \
	$(TF_APPLY) -target aws_s3_bucket_object.stage-cloud-config \
				-target aws_s3_bucket_object.stage-filebeat-config-tmpl \
				-target aws_s3_bucket_object.admiral-cloud-config;

plan_stage_user_data: init_stage_user_data
	cd $(BUILD_STAGE); \
	$(TF_PLAN) -target aws_s3_bucket_object.stage-cloud-config \
			   -target aws_s3_bucket_object.stage-filebeat-config-tmpl \
			   -target aws_s3_bucket_object.admiral-cloud-config;

refresh_stage_user_data: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_REFRESH) -target aws_s3_bucket_object.stage-cloud-config \
				  -target aws_s3_bucket_object.stage-filebeat-config-tmpl \
                  -target aws_s3_bucket_object.admiral-cloud-config;

destroy_stage_user_data: | $(TF_PROVIDER_STAGE) pull_stage_state
	cd $(BUILD_STAGE); \
	$(TF_DESTROY)	-target aws_s3_bucket_object.stage-cloud-config \
					-target aws_s3_bucket_object.stage-filebeat-config-tmpl \
                    -target aws_s3_bucket_object.admiral-cloud-config;

clean_stage_user_data: destroy_stage_user_data
	rm -f $(BUILD_STAGE)/stage-user-data.tf

init_stage_user_data: init_stage
		cp -rf $(INFRA_STAGE)/instance-pool/data/worker/ $(BUILD_STAGE)/data;
		cp -rf $(INFRA_STAGE)/instance-pool/stage-user-data.tf $(BUILD_STAGE);
		cp -rf $(INFRA_STAGE)/instance-pool/user-data/* $(BUILD_STAGE)/user-data;
		cd $(BUILD_STAGE); $(TF_GET);

.PHONY: stage_user_data destroy_stage_user_data refresh_stage_user_data plan_stage_user_data init_stage_user_data clean_stage_user_data