# Separate from storage because needs to made after network
efs_qa: plan_efs_qa
	cd $(BUILD_QA); \
	$(TF_APPLY)	-target module.efs \
							-target module.efs-mount-targets;
# Specifiy nested modules explicitly while using terraform apply, plan and destroy
# https://github.com/hashicorp/terraform/issues/5870

plan_efs_qa: init_efs_qa
	cd $(BUILD_QA); \
	$(TF_PLAN) -target module.efs \
						 -target module.efs-mount-targets;

refresh_efs_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_REFRESH) -target module.efs \
								-target module.efs-mount-targets;

destroy_efs_qa: | $(TF_PROVIDER_QA) pull_qa_state
	cd $(BUILD_QA); \
	$(TF_DESTROY) -target module.efs \
								-target module.efs-mount-targets;

clean_efs_qa: destroy_efs_qa
	rm -f $(BUILD_QA)/efs.tf

init_efs_qa: init_qa
		cp -rf $(INFRA_QA)/storage/efs.tf $(BUILD_QA)
		cd $(BUILD_QA); $(TF_GET);

.PHONY: efs_qa destroy_efs_qa refresh_efs_qa plan_efs_qa init_efs_qa clean_efs_qa