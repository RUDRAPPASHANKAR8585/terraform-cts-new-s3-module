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

enable_kms_encryption = true

kms_key_arn = "arn:aws:kms:ap-south-1:700030738273:key/mrk-2e9773e9031f4e6a8048093552558727"

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

    destination_type = "sns"

    destination_arn = "arn:aws:sns:ap-south-1:700030738273:poc-s3"

    events = [

      "s3:ObjectCreated:*"

    ]

    filter_prefix = "images/"

    filter_suffix = ".jpg"

  },
  {

    destination_type = "sqs"

    destination_arn = "arn:aws:sqs:ap-south-1:700030738273:s3-poc"

    events = [

      "s3:ObjectRemoved:*"

    ]

    filter_prefix = "images/"

    filter_suffix = ".jpg"

  },
  {

    destination_type = "lambda"

    destination_arn = "arn:aws:lambda:ap-south-1:700030738273:function:s3-poc"

    events = [

      "s3:ObjectRestore:*"

    ]

    filter_prefix = "images/"

    filter_suffix = ".jpg"

  }

]

enable_eventbridge_notifications = true

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
