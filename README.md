# Stakater Infrastructure Reference
## Table of Contents##

- [Overview](#overview)
- [Setup AWS credentials](#setup-aws-credentials)
- [Install tools](#install-tools)
- [Quick start](#quick-start)
- [Customization](#customization)

## Overview

This is a practical reference implementation of Stakater Blueprints
The entire infrastructure is managed by [Terraform](https://www.terraform.io/intro/index.html).

## Setup AWS credentials

Go to [AWS Console](https://console.aws.amazon.com/).

1. Signup AWS account if you don't already have one. The default EC2 instances created by this tool is covered by AWS Free Tier (https://aws.amazon.com/free/) service.
2. Create a group `stakater` with `AdministratorAccess` policy.
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

###To Create:
Usage: `make (<resource> | destroy_<resource> | plan_<resource> | refresh_<resource> | show | graph )``

Available resources: network

For example: `make plan_network` to show what resources are planned for network

###NOTE: The bucket name specified for `TF_STATE_BUCKET_NAME` in the Makefile should exist and should be accessible.


###To Destroy
Usage: `make destroy_<resource>`

For example: `make destroy_network`
