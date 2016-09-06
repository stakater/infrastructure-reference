$(BUILD): init_build_dir

init_build_dir:
	@rm -f $(BUILD)/*.tf
	@mkdir -p $(BUILD)
	@mkdir -p $(BUILD_DEV)
	@mkdir -p $(BUILD_PROD)
	@mkdir -p $(BUILD_QA)
	@mkdir -p $(BUILD_GLOBAL_ADMIRAL)

.PHONY: init_build_dir