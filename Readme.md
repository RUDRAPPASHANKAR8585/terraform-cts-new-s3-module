terraform module : terraform-aws-s3

###########################################################
# Introduction
###########################################################

This Terraform module provisions and manages Amazon S3 Buckets
in AWS using production ready and configurable Amazon S3 features.

The module supports commonly used Amazon S3 capabilities including:

- Bucket Configuration
- Server Side Encryption
- Versioning
- Ownership Controls
- Public Access Block
- Server Access Logging
- Static Website Hosting
- Event Notifications
- Amazon EventBridge Notifications
- Transfer Acceleration
- Requester Pays
- Object Lock

The module has been designed with simplicity, flexibility and
future extensibility in mind.


###########################################################
# Supported Features
###########################################################

| Feature | Supported |
|--------|----------|
| Bucket Configuration | Yes |
| Server Side Encryption | Yes |
| Versioning | Yes |
| Ownership Controls | Yes |
| Public Access Block | Yes |
| Server Access Logging | Yes |
| Static Website Hosting | Yes |
| Event Notifications | Yes |
| Amazon EventBridge Notifications | Yes |
| Transfer Acceleration | Yes |
| Requester Pays | Yes |
| Object Lock | Yes |


###########################################################
# Unsupported Features
###########################################################

The following Amazon S3 features are not supported in the
current release.

- Lifecycle Rules
- Replication Rules
- Inventory Configurations
- Bucket Policies
- Cross-Origin Resource Sharing (CORS)
- CloudWatch Log Delivery
- Intelligent Tiering
- Analytics Configurations
- Amazon S3 Access Points
- Multi Region Access Points
- Storage Lens


###########################################################
# Requirements
###########################################################

Terraform Version

| Name | Compatible Version |
|------|------------------|
| Terraform | >=1.10.0 |


Provider Version

| Name | Compatible Version |
|------|------------------|
| AWS | >=5.0 |


###########################################################
# Module Structure
###########################################################

terraform-aws-s3/

│
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
└── module
      │
      └── s3
           │
           ├── main.tf
           ├── variables.tf
           └── outputs.tf



###########################################################
# Getting Started
###########################################################

Clone Terraform Module

git clone XXXXXXX


Move to Terraform Directory

cd terraform-aws-s3


Initialize Terraform

terraform init


Validate Terraform

terraform validate


Generate Execution Plan

terraform plan


Apply Configuration

terraform apply



###########################################################
# Quick Start
###########################################################

module "s3" {

source="./module/s3"

bucket_name="my-s3-bucket"

environment="DEV"

project="POC"

enable_versioning=true

}


###########################################################
# Feature Wise Usage Guide
###########################################################


1. Bucket Configuration

2. Server Side Encryption

3. Versioning

4. Ownership Controls

5. Public Access Block

6. Server Access Logging

7. Static Website Hosting

8. Event Notifications

9. Amazon EventBridge Notifications

10. Transfer Acceleration

11. Requester Pays

12. Object Lock



###########################################################
# Static Website Hosting
###########################################################


Disabled

static_website_type = null



Website Hosting

static_website_type="website"

website_index_document="index.html"

website_error_document="error.html"



Redirect Website Hosting

static_website_type="redirect"

redirect_host_name="www.google.com"

redirect_protocol="https"



###########################################################
# Event Notifications
###########################################################


Enable Event Notifications


enable_event_notifications=true


SNS Example


event_notifications=[

{

destination_type="sns"

destination_arn="xxxx"

events=[

"s3:ObjectCreated:*"

]

filter_prefix="images/"

filter_suffix=".jpg"

}

]


Lambda Example


event_notifications=[

{

destination_type="lambda"

destination_arn="xxxx"

events=[

"s3:ObjectRestore:*"

]

}

]


SQS Example


event_notifications=[

{

destination_type="sqs"

destination_arn="xxxx"

events=[

"s3:ObjectRemoved:*"

]

}

]



###########################################################
# Amazon EventBridge Notifications
###########################################################


Disabled


enable_eventbridge_notifications=false



Enabled


enable_eventbridge_notifications=true



###########################################################
# Complete Example
###########################################################


(terraform.tfvars example)



###########################################################
# Inputs
###########################################################

| Name | Description | Type | Default | Required |
|------|------------|------|---------|---------|
| bucket_name | Amazon S3 Bucket Name | string | n/a | Yes |
| enable_versioning | Enable Versioning | bool | false | No |
| static_website_type | Website Hosting Type | string | null | No |
| enable_event_notifications | Enable Event Notifications | bool | false | No |
| enable_eventbridge_notifications | Enable EventBridge Notifications | bool | false | No |

etc........



###########################################################
# Outputs
###########################################################

| Name | Description |
|------|-------------|
| bucket_name | Amazon S3 Bucket Name |
| bucket_arn | Amazon S3 Bucket ARN |
| bucket_id | Amazon S3 Bucket ID |
| bucket_domain_name | Bucket Domain Name |
| bucket_regional_domain_name | Regional Domain Name |
| website_endpoint | Website Endpoint |
| hosted_zone_id | Hosted Zone ID |



###########################################################
# Limitations
###########################################################

- CloudWatch Log Delivery is not currently supported.
- Lifecycle Rules are not currently supported.
- Replication Rules are not currently supported.
- Bucket Policies are not currently supported.
- Inventory Configurations are not currently supported.
- CORS Rules are not currently supported.



###########################################################
# Future Enhancements
###########################################################

Planned features for future releases.

- Lifecycle Rules
- Replication Rules
- Bucket Policies
- Inventory Configurations
- CORS Rules
- CloudWatch Log Delivery
- Intelligent Tiering
- Analytics Configurations
- Access Points
- Storage Lens
- Multi Region Access Points



###########################################################
# Contributing
###########################################################

Contributions, feature requests and improvements are welcome.



###########################################################
# License
###########################################################

MIT License
