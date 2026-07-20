####################################
# Bucket Configuration
####################################

variable "bucket_name" {

  description = "Name of the S3 bucket. Must be globally unique."

  type = string


  validation {

    condition = can(regex(
      "^[a-z0-9][a-z0-9.-]+[a-z0-9]$",
      var.bucket_name
    ))

    error_message = "Bucket name must follow AWS naming conventions."

  }

}

variable "force_destroy" {
  description = "Allow Terraform to delete all objects in the bucket when destroying it."
  type        = bool
  default     = false
}

##############################################################################
# Server Side Encryption Configuration
##############################################################################

variable "enable_kms_encryption" {

  description = "Enable SSE-KMS encryption for the S3 bucket."
  type        = bool
  default     = false

}


variable "kms_key_arn" {

  description = "The ARN of the KMS key used for SSE-KMS encryption."

  type     = string
  default  = null
  nullable = true

}

####################################
# Versioning
####################################

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket."
  type        = bool
  default     = true
}

####################################
# Public Access Block
####################################

variable "block_public_acls" {
  description = "Block public ACLs."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets."
  type        = bool
  default     = true
}

####################################
# Ownership Controls
####################################

variable "object_ownership" {
  description = "S3 Object Ownership setting."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition = contains([
      "BucketOwnerEnforced",
      "BucketOwnerPreferred",
      "ObjectWriter"
    ], var.object_ownership)

    error_message = "Valid values are BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  }
}
####################################
# Tags
####################################

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "application" {
  description = "Application name."
  type        = string
}

variable "owner" {
  description = "Application owner."
  type        = string
}

variable "cost_center" {
  description = "Cost center."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags."

  type = map(string)

  default = {}
}

####################################
# Object Lock
####################################

variable "enable_object_lock" {
  description = "Enable object lock."

  type = bool

  default = false
}

variable "object_lock_mode" {
  description = "Default retention mode for S3 Object Lock."
  type        = string
  default     = "GOVERNANCE"

  validation {

    condition = contains(
      [
        "GOVERNANCE",
        "COMPLIANCE"
      ],
      upper(coalesce(var.object_lock_mode, "GOVERNANCE"))
    )

    error_message = "Valid values are GOVERNANCE or COMPLIANCE."

  }
}

variable "object_lock_days" {
  description = "Retention period in days."
  type        = number
  default     = null

  validation {

    condition = (
      var.object_lock_days == null ?
      true :
      var.object_lock_days > 0
    )
    error_message = "Retention days must be greater than zero."
  }
}

##############################################################################
# Event Notifications
##############################################################################

variable "enable_event_notifications" {

  description = "Enable Amazon S3 Event Notifications."

  type = bool

  default = false

}


variable "event_notifications" {

  description = <<-EOT
List of Amazon S3 Event Notification configurations.

Supported destination types:
- sns
- sqs
- lambda

Supported filter options:
- filter_prefix (Optional)
- filter_suffix (Optional)

Multiple notification configurations are supported.
Multiple Amazon S3 event types are supported for each notification.

Common Amazon S3 Event Types:

Object Creation:
- s3:ObjectCreated:*
- s3:ObjectCreated:Put
- s3:ObjectCreated:Post
- s3:ObjectCreated:Copy
- s3:ObjectCreated:CompleteMultipartUpload

Object Removal:
- s3:ObjectRemoved:*
- s3:ObjectRemoved:Delete
- s3:ObjectRemoved:DeleteMarkerCreated

Object Restore:
- s3:ObjectRestore:*
- s3:ObjectRestore:Post
- s3:ObjectRestore:Completed
- s3:ObjectRestore:Delete

Object Tagging:
- s3:ObjectTagging:*
- s3:ObjectTagging:Put
- s3:ObjectTagging:Delete

Object ACL:
- s3:ObjectAcl:Put

Replication:
- s3:Replication:*
- s3:Replication:OperationFailedReplication
- s3:Replication:OperationReplicatedAfterThreshold
- s3:Replication:OperationMissedThreshold
- s3:Replication:OperationNotTracked

Lifecycle:
- s3:LifecycleTransition
- s3:LifecycleExpiration:*
- s3:LifecycleExpiration:Delete
- s3:LifecycleExpiration:DeleteMarkerCreated

Intelligent Tiering:
- s3:IntelligentTiering

Annotation:
- s3:ObjectAnnotation:*
- s3:ObjectAnnotation:Put
- s3:ObjectAnnotation:Delete

Example:

event_notifications = [

  {
    destination_type = "sns"

    destination_arn = "arn:aws:sns:REGION:ACCOUNT_ID:TOPIC_NAME"

    events = [
      "s3:ObjectCreated:*"
    ]

    filter_prefix = "images/"
    filter_suffix = ".jpg"
  },

  {
    destination_type = "sqs"

    destination_arn = "arn:aws:sqs:REGION:ACCOUNT_ID:QUEUE_NAME"

    events = [
      "s3:ObjectRemoved:*"
    ]
  },

  {
    destination_type = "lambda"

    destination_arn = "arn:aws:lambda:REGION:ACCOUNT_ID:function:FUNCTION_NAME"

    events = [
      "s3:ObjectRestore:*"
    ]
  }

]

NOTES:
- Multiple notification configurations are supported.
- Multiple Amazon S3 event types are supported.
- Prefix and suffix filters are optional.
- Destination resources must already exist.
- Destination resources must grant the required permissions to Amazon S3.
- This module does not restrict supported Amazon S3 event types.
- Any valid Amazon S3 event notification supported by AWS may be provided.
- Future Amazon S3 event types introduced by AWS are automatically supported.

Refer to the AWS documentation for newly introduced event types.
EOT

  type = list(object({

    destination_type = string

    destination_arn = string

    events = list(string)

    filter_prefix = optional(string)

    filter_suffix = optional(string)

  }))

  default = []


  ###########################################################################
  # Validations
  ###########################################################################

  validation {

    condition = alltrue([

      for notification in var.event_notifications :

      contains(
        ["sns", "sqs", "lambda"],
        lower(notification.destination_type)
      )

    ])

    error_message = "destination_type must be one of sns, sqs or lambda."

  }


  validation {

    condition = alltrue([

      for notification in var.event_notifications :

      length(notification.events) > 0

    ])

    error_message = "At least one event must be provided for every notification configuration."

  }


  validation {

    condition = alltrue([

      for notification in var.event_notifications :

      trimspace(notification.destination_arn) != ""

    ])

    error_message = "destination_arn cannot be empty."

  }

}

##############################################################################
# Amazon EventBridge Notifications
##############################################################################

variable "enable_eventbridge_notifications" {

  description = <<-EOT

Enable Amazon EventBridge notifications for all
Amazon S3 bucket events.

Supported Values:
- true
- false

Examples:

enable_eventbridge_notifications = false

enable_eventbridge_notifications = true


NOTES:
- Defaults to false.
- Amazon EventBridge receives all supported
  Amazon S3 bucket events.
- Amazon EventBridge rules and targets must be
  configured separately.
- No additional configuration is required
  within this module.

EOT

  type = bool

  default = false

}

##############################################################################
# Static Website Hosting
##############################################################################

variable "static_website_type" {

  description = <<-EOT

Amazon S3 Static Website Hosting configuration.

Supported Values:
- null
- website
- redirect

Examples:

static_website_type = null

static_website_type = "website"

static_website_type = "redirect"


NOTES:
- null disables Static Website Hosting.
- website enables Static Website Hosting.
- redirect enables Redirect Website Hosting.
- Only one hosting type may be configured at a time.

EOT

  type    = string
  default = null


  validation {

    condition = (

      var.static_website_type == null ?

      true :

      contains(
        [
          "website",
          "redirect"
        ],

        lower(var.static_website_type)

      )

    )

    error_message = "Valid values are website or redirect."

  }

}


##############################################################################
# Website Hosting
##############################################################################

variable "website_index_document" {

  description = "Index document for Amazon S3 Static Website Hosting."

  type    = string
  default = null

}

variable "website_error_document" {

  description = "Error document for Amazon S3 Static Website Hosting."

  type    = string
  default = null

}


##############################################################################
# Redirect Hosting
##############################################################################

variable "redirect_host_name" {

  description = "Host name used when redirecting website requests."

  type    = string
  default = null

}



variable "redirect_protocol" {

  description = <<-EOT

Supported Values:
- http
- https
- null

EOT

  type    = string
  default = null


  validation {

    condition = (

      var.redirect_protocol == null ?

      true :

      contains(
        [
          "http",
          "https"
        ],

        lower(var.redirect_protocol)

      )

    )

    error_message = "Valid values are http or https."

  }

}


####################################
# Transfer Acceleration
####################################

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration."
  type        = bool
  default     = false
}

####################################
# Requester Pays
####################################

variable "enable_requester_pays" {
  description = "Enable Requester Pays for the bucket."
  type        = bool
  default     = false
}   
