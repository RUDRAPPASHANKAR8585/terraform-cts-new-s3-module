#################################
# AWS
#################################

region = "ap-south-1"

#################################
# Bucket
#################################

bucket_name = "shankar-poc-s3"

environment = "POC"

project = "NOVARTIS"

application = "S3"

owner = "SHANKAR"

cost_center = "0000"

additional_tags = {}


#################################
# Encryption
#################################

#################################
# Default Encryption
#################################
encryption_type = "aws:kms:dsse"

kms_key_type = "CUSTOMER_MANAGED"

kms_key_alias = "poc/kms"

bucket_key_enabled = true

#################################
# Versioning
#################################

enable_versioning = true


#################################
# Ownership
#################################

object_ownership = "BucketOwnerEnforced"


#################################
# Public Access
#################################

block_public_acls       = true
ignore_public_acls      = true
block_public_policy     = true
restrict_public_buckets = true

#################################
# Static Website Hosting
#################################

static_website_type = "redirect"

#################################
# Static Website Hosting
#################################

website_index_document = null

website_error_document = null

#################################
# Static Website Hosting
#################################

redirect_host_name = "www.google.com"

redirect_protocol = "https"



#################################
# Notifications
#################################

enable_event_notifications = true

event_notifications = [

  {
    destination_type = "lambda"

    destination_arn = "arn:aws:lambda:ap-south-1:700030738273:function:s3-poc"

    events = [

      "s3:ObjectCreated:*"

    ]

    manage_permission = true
  },
  {
    destination_type = "sqs"

    destination_arn = "arn:aws:sqs:ap-south-1:700030738273:cts-poc-s3-notify"

    events = [

      "s3:ObjectRemoved:*"

    ]

    filter_prefix = "images/"

    filter_suffix = ".jpg"

    manage_permission = true
  },
  {
    destination_type = "sns"

    destination_arn = "arn:aws:sns:ap-south-1:700030738273:poc-s3"

    events = [

      "s3:ObjectRestore:*"

    ]

    filter_prefix = "images/"

    filter_suffix = ".jpg"

    manage_permission = false
  }
]

enable_eventbridge_notifications = true

python_command = "python"

#################################
# Transfer Acceleration
#################################

enable_transfer_acceleration = false


#################################
# Requester Pays
#################################

enable_requester_pays = false


#################################
# Object Lock
#################################

enable_object_lock = false

object_lock_mode = null

object_lock_days = null
