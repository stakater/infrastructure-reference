###################
## Customization ##
###################
# Profile
AWS_PROFILE := stakater-reference
# Stack name may only contain letters (Uppercase & lowercase), numbers or the characters . _ -
STACK_NAME := stakater-reference

# To prevent you mistakenly using a wrong account (and end up destroying live environment),
# a list of allowed AWS account IDs should be defined:
#ALLOWED_ACCOUNT_IDS := "123456789012","012345678901"

# Bucket which stores terraform remote state
TF_STATE_BUCKET_NAME := $(STACK_NAME)-terraform-state
TF_STATE_GLOBAL_ADMIRAL_KEY := global-admiral/terraform.tfstate
TF_STATE_DEV_KEY := dev/terraform.tfstate
TF_STATE_QA_KEY := qa/terraform.tfstate
TF_STATE_PROD_KEY := prod/terraform.tfstate
TF_STATE_STAGE_KEY := stage/terraform.tfstate

# Dev env bucket names defined here, as these are to be allowed
# in policy of the instance that deploys to stage (e.g. GoCD) and
# are to be passed to pipelines by GoCD
DEV_CLOUDINIT_BUCKET_NAME := $(STACK_NAME)-dev-cloudinit
DEV_CONFIG_BUCKET_NAME := $(STACK_NAME)-dev-config

# QA env bucket names defined here, as these are to be allowed
# in policy of the instance that deploys to stage (e.g. GoCD) and
# are to be passed to pipelines by GoCD
QA_CLOUDINIT_BUCKET_NAME := $(STACK_NAME)-qa-cloudinit
QA_CONFIG_BUCKET_NAME := $(STACK_NAME)-qa-config

# Prod env bucket names defined here, as these are to be allowed
# in policy of the instance that deploys to prod (e.g. GoCD) in order to
# download cloudconfig and upload keypairs
PROD_CLOUDINIT_BUCKET_NAME := $(STACK_NAME)-prod-cloudinit
PROD_CONFIG_BUCKET_NAME := $(STACK_NAME)-prod-config

# Stage env bucket names defined here, as these are to be allowed
# in policy of the instance that deploys to stage (e.g. GoCD) in order to
# download cloudconfig and upload keypairs
STAGE_CLOUDINIT_BUCKET_NAME := $(STACK_NAME)-stage-cloudinit
STAGE_CONFIG_BUCKET_NAME := $(STACK_NAME)-stage-config


# Database properties
DEV_DATABASE_USERNAME := root
DEV_DATABASE_PASSWORD := root
DEV_DATABASE_NAME := mydb

QA_DATABASE_USERNAME := root
QA_DATABASE_PASSWORD := root
QA_DATABASE_NAME := mydb

PROD_DATABASE_USERNAME := root
PROD_DATABASE_PASSWORD := root
PROD_DATABASE_NAME := mydb

STAGE_DATABASE_USERNAME := root
STAGE_DATABASE_PASSWORD := root
STAGE_DATABASE_NAME := mydb

# For get-vars.sh
COREOS_UPDATE_CHANNEL=stable
VM_TYPE=hvm

# Working Directories
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT_DIR)scripts
RESOURCES := $(ROOT_DIR)resources
BUILD := $(ROOT_DIR)build

INFRASTRUCTURE_MODULES := $(ROOT_DIR)infrastructure-modules
INFRA_DEV := $(INFRASTRUCTURE_MODULES)/dev
INFRA_QA := $(INFRASTRUCTURE_MODULES)/qa
INFRA_PROD := $(INFRASTRUCTURE_MODULES)/prod
INFRA_STAGE := $(INFRASTRUCTURE_MODULES)/stage
INFRA_GLOBAL_ADMIRAL := $(INFRASTRUCTURE_MODULES)/global-admiral

# Environment Build Directories
BUILD_DEV := $(BUILD)/dev
BUILD_QA := $(BUILD)/qa
BUILD_PROD := $(BUILD)/prod
BUILD_STAGE := $(BUILD)/stage
BUILD_GLOBAL_ADMIRAL := $(BUILD)/global-admiral

# Environment specific files
MODULE_VARS_DEV=$(BUILD_DEV)/module_vars.tf
MODULE_VARS_QA=$(BUILD_QA)/module_vars.tf
MODULE_VARS_PROD=$(BUILD_PROD)/module_vars.tf
MODULE_VARS_STAGE=$(BUILD_STAGE)/module_vars.tf
MODULE_VARS_GLOBAL_ADMIRAL=$(BUILD_GLOBAL_ADMIRAL)/module_vars.tf

# Terraform provider files
TF_PROVIDER_DEV := $(BUILD_DEV)/provider.tf
TF_PROVIDER_QA := $(BUILD_QA)/provider.tf
TF_PROVIDER_PROD := $(BUILD_PROD)/provider.tf
TF_PROVIDER_STAGE := $(BUILD_STAGE)/provider.tf
TF_PROVIDER_GLOBAL_ADMIRAL := $(BUILD_GLOBAL_ADMIRAL)/provider.tf

TF_BACKEND_CONFIG_GLOBAL_ADMIRAL := $(BUILD_GLOBAL_ADMIRAL)/backend-config.tfvars
# Terraform commands
TF_GET := terraform get -update
TF_SHOW := terraform show -module-depth=2
TF_GRAPH := terraform graph -draw-cycles -verbose
TF_PLAN := terraform plan -module-depth=2
TF_APPLY := terraform apply
TF_REFRESH := terraform refresh
TF_DESTROY := terraform destroy -force

##########################
## End of customization ##
##########################

export

help:
	@echo "Usage: make (<resource> | destroy_<resource> | plan_<resource> | refresh_<resource> | show | graph )"
	@echo "Available resources: network"
	@echo "For example: make plan_network # to show what resources are planned for network"

destroy:
	@echo "Usage: make destroy_<resource>"
	@echo "For example: make destroy_network"
	@echo "Node: destroy may fail because of outstanding dependences"

# Load all resouces makefile
include resources/makefiles/*.mk
include resources/makefiles/*/*.mk
include resources/makefiles/*/*/*.mk

.PHONY: destroy help
