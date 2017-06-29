# Stakater Infrastructure Reference
## Table of Contents##

- [Overview](#overview)
- [Setup AWS credentials](#setup-aws-credentials)
- [Install tools](#install-tools)
- [Quick start](#quick-start)
- [Customization](#customization)
- [Building Infrastructure](#building-infrastructure)
- [One time Setup](#one-time-setup) 
- [Troubleshooting](#troubleshooting) 

## Overview

This is a practical reference implementation of Stakater Blueprints
The entire infrastructure is managed by [Terraform](https://www.terraform.io/intro/index.html).

## Setup AWS credentials

Go to [AWS Console](https://console.aws.amazon.com/).

1. Signup AWS account if you don't already have one. The default EC2 instances created by this tool is covered by AWS Free Tier (https://aws.amazon.com/free/) service.
2. Create a group `stakater` with `AdministratorAccess` policy or using the [stakater-policy](https://github.com/stakater/infrastructure-reference/blob/master/stakater-policy.json) given in the repo.
3. Create a user `stakater` and __Download__ the user credentials.
4. Add user `stakater` to group `stakater`.

## Install tools

If you use [Vagrant](https://www.vagrantup.com/), you can skip this section and go to
[Quick Start](#quick-start) section.

Instructions for install tools on MacOS:

1. Install [Terraform](http://www.terraform.io/downloads.html)

    ```
    $ brew update
    $ brew install terraform
    ```
    or
    ```
    $ mkdir -p ~/bin/terraform
    $ cd ~/bin/terraform
    $ curl -L -O https://dl.bintray.com/mitchellh/terraform/terraform_0.6.0_darwin_amd64.zip
    $ unzip terraform_0.6.0_darwin_amd64.zip
    ```

2. Install [Jq](http://stedolan.github.io/jq/)
    ```
    $ brew install jq
    ```

3. Install [AWS CLI](https://github.com/aws/aws-cli)
    ```
    $ brew install awscli
    ```
    or

    ```
    $ sudo easy_install pip
    $ sudo pip install --upgrade awscli
    ```

For other platforms, follow the tool links and instructions on tool sites.

## Quick start

#### Clone the repo:
```
$ git clone https://github.com/stakater/infrastructure-reference
$ cd infrastructure-reference
```

#### Run Vagrant ubuntu box with terraform installed (Optional)
If you use Vagrant, instead of install tools on your host machine, there is Vagranetfile for a Ubuntu box with all the necessary tools installed:

```
$ vagrant up
$ vagrant ssh
$ cd infrastructure-reference
```

#### Configure AWS profile with `stakater-reference` credentials

```
$ aws configure --profile stakater-reference
```

Use the [downloaded aws user credentials](#setup-aws-credentials) when prompted.

The above command will create a __stakater-reference__ profile authentication section in ~/.aws/config and ~/.aws/credentials files. The build process bellow will automatically configure Terraform AWS provider credentials using this profile.

## Customization
You can customize stakater settings by changing the variables in the `Makefile`.

Following is the list of variables in the `Makefile` and their description: 

| Variables                   | Description                                                                                                                              |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------------------------|                                                                                                                                      |
| AWS_PROFILE                 | Name of the AWS profile stakater is going to use  ([Setup AWS credentials](#setup-aws-credentials))                                      |
| STACK_NAME                  | Name of the stack you are about to build with stakater. (This name will be used in all resources created)                                |
| TF_STATE_BUCKET_NAME        | Name of the (already existing) S3 bucket in which the terraform state files will be stored                                               |
| TF_STATE_GLOBAL_ADMIRAL_KEY | Key of the global admiral state file in the bucket (i.e. full path of the state file)                                                    |
| TF_STATE_DEV_KEY            | Key of the Development environment state file in the bucket (i.e. full path of the state file)                                           |
| TF_STATE_QA_KEY             | Key of the QA environment state file in the bucket (i.e. full path of the state file)                                                    |
| TF_STATE_PROD_KEY           | Key of the Production environment state file in the bucket (i.e. full path of the state file)                                            |
| PROD_CLOUDINIT_BUCKET_NAME  | Name of the Cloudinit S3 Bucket for Production environment                                                                               |
| PROD_CONFIG_BUCKET_NAME     | Name of the Config S3 Bucket for Production environment                                                                                  |
| DEV_DATABASE_USERNAME       | Database username for development database (Used for both Mysql instance-pool OR Aurora DB)                                              |
| DEV_DATABASE_PASSWORD       | Database password for the provided username AND root password, for development database (Used for both Mysql instance-pool OR Aurora DB) |
| DEV_DATABASE_NAME           | Database name for QA database (Used for both Mysql instance-pool OR Aurora DB)                                                           |
| QA_DATABASE_USERNAME        | Database username for QA database (Used for both Mysql instance-pool OR Aurora DB)                                                       |
| QA_DATABASE_PASSWORD        | Database password for the provided username AND root password, for QA database (Used for both Mysql instance-pool OR Aurora DB)          |
| QA_DATABASE_NAME            | Database username for QA database (Used for both Mysql instance-pool OR Aurora DB)                                                       |
| PROD_DATABASE_USERNAME | Database username for production database (Aurora DB)                                                            |
| PROD_DATABASE_PASSWORD | Database password for the provided username AND root password, for production database (Aurora DB)               |
| PROD_DATABASE_NAME     | Database name for production database (Aurora DB)                                                                |
| COREOS_UPDATE_CHANNEL  | Update channel for fetching Core OS AMI ID (stable, beta, alpha) (We recommend to keep it at `stable` (default)) |

#### GoCD Configuration
* Set up GoCD Configuration file (`cruise-config.xml`)
* Set up the `gocd.parameters.txt` file.

(For more information on how to configure GoCD, follow the link)

#### Certificates
If you want to use SSL certificates on your load balancers, import those certificates in AWS Certification Manager, and pass the ARN of the certificate from GoCD. (More in GoCD configuration)

#### Terraform State Bucket
You will need to create a S3 bucket (in the same region assigned to the AWS profile your using), for storing terraform remote states.

The name of this bucket should be provided against the `TF_STATE_BUCKET_NAME` variable in the `Makefile`

#### Advanced Configuration:
Advanced options such as:
* Adding/Removing ELBs for a module
* Adding/Updating/Removing Security group rules for a module
* Chaning the size and name of attached EBS volumes
* Adding/Updating/Removing Route53 entries for a module
* Adding/Updating/Removing Scale policies for autoscaling groups 

can be configured in the terraform files for modules in environments' folder inside `infrastructure-modules` folder. 

## Building Infrastructure
###To Create:

To Build your infrastructure consisting of Global Admiral and Dev,QA,Prod Environments run the following command:

```
make all
```

This will in turn call `make global_admiral dev qa prod` in the given order.

You can also make each environment or resource separately by calling make in the following format: 

For environments: 

* make global_admiral
* make dev
* make qa
* make prod

For Resources: 
```
Usage: make (<resource> | destroy_<resource> | plan_<resource> | refresh_<resource> )`
```

For example: make plan_network to show what resources are planned for network
NOTE: The bucket name specified for TF_STATE_BUCKET_NAME in the Makefile should exist and should be accessible.
###To Destroy

Usage: make destroy_<resource>

For example: make destroy_network

## One time Setup 
Once your infrastructure has been set up, you'll need to perform the following steps as a part of one time setup of the infrastructure:

* Prepare your application for Stakater (link)
* Assign agents to GoCD (link)

## Troubleshooting


#### Known Issues while making Infrastructure
* #### Error Creating Launch Configuration

    **Error**:  
    `aws_launch_configuration.lc_ebs: Error creating launch configuration: ValidationError: Invalid IamInstanceProfile`

    This is an intermittent and can be avoided by performing the specific step again

    ##### Reference:
      * https://github.com/hashicorp/terraform/issues/1885
      * https://github.com/hashicorp/terraform/issues/9474
      
* #### Error Creating Launch Configuration 

    **Error**:  
    `aws_launch_configuration.lc: Error creating launch configuration: ValidationError: You are not authorized to perform this operation.`

    This is an intermittent and can be avoided by performing the specific step again
    
    ##### Reference:
      * https://github.com/hashicorp/terraform/issues/5862
      * https://github.com/hashicorp/terraform/issues/7198


* #### Attribute missing from Remote State

    **Error**:  
    `Resource 'data.terraform_remote_state.global-admiral' does not have attribute 'variable_name' for variable 'data.terraform_remote_state.global-admiral.variable_name'`

    For example: `data.terraform_remote_state.global-admiral.private_app_route_table_ids`
    
    In case make fails due to unknown output referenced in global-admiral state, call `make refresh_global_admiral` and then make.
    
    ##### Reference: 
      * https://github.com/hashicorp/terraform/issues/2598

    ##### NOTE:
      Once you refresh global admiral state, global admiral will remove vpc-peering connections created by other VPCs (in their tf states), as global admiral is not aware of them.
    Please be sure to re-make the network module of other environments in order to re-create the vpc-connection IF it is removed as a result of refreshing. (Work in progress to solve this issue)
    
    e.g. `make network_dev`, `make network_qa` or `make network_prod`

* #### Network Timeout Error 
    
    **Error**: 
      `timeout while waiting for state to become 'successful'` OR `Network time out waiting for I/O...` 
    
    This issue occurs due to slow network response from AWS or slow internet connection from the requesting side. 
    
    Retry using a better internet connection. 
    
* #### Error while Creating Keypair
    
    **Error**: 
    `Cannot create keypair: Permission denied`
    
    Issue occurs while creating keypair using the aws-keypair.sh script, this is an intermittent in issue, and can be avoided by retrying
    
* #### Error while Uploading Keypair
    
    **Error**: 
    `Could not upload keypair: Access Denied`
    
    Issue occurs while uploading the keypair after it has been created using AWS CLI (aws-keypair.sh), this is an intermittent in issue, and can be avoided by retrying the make. 
