all: global_admiral dev qa prod

plan_all: plan_global_admiral plan_dev plan_qa plan_prod

refresh_all: refresh_global_admiral refresh_dev refresh_qa refresh_prod

destroy_all: destroy_prod destroy_qa destroy_dev destroy_global_admiral

clean_all: destroy_all
	rm -f $(BUILD)/*
	rm -rf $(BUILD)/.terraform

.PHONY: all destroy_all refresh_all plan_all
