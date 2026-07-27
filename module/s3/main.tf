##############################################################################
# S3 Bucket Configuration
##############################################################################

resource "aws_s3_bucket" "this" {

  bucket = local.generated_bucket_name

  force_destroy = var.force_destroy

  tags = merge(

    var.additional_tags,

    {
      Environment = var.environment
      Project     = var.project
      Application = var.application
      Owner       = var.owner
      CostCenter  = var.cost_center
    },

    {
      Name      = var.bucket_name
      ManagedBy = "Terraform"
      Terraform = "true"
    }

  )

}

##############################################################################
# Server-Side Encryption Configuration
##############################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {

  bucket = aws_s3_bucket.this.id

  lifecycle {

    ##########################################################################
    # Customer-managed KMS key validation
    ##########################################################################

    precondition {

      condition = !(
        var.kms_key_type == "CUSTOMER_MANAGED"
        &&
        (
          var.encryption_type == "aws:kms"
          ||
          var.encryption_type == "aws:kms:dsse"
        )
        &&
        try(length(trimspace(var.kms_key_alias)) == 0, true)
      )

      error_message = "kms_key_arn must be provided when using a customer-managed KMS key."

    }

    ##########################################################################
    # Prevent unnecessary KMS options for SSE-S3
    ##########################################################################

    precondition {

      condition = !(
        var.encryption_type == "AES256"
        &&
        (
          var.kms_key_type != "AWS_MANAGED"
          ||
          var.kms_key_alias != null
        )
      )

      error_message = "kms_key_type and kms_key_arn are not applicable when encryption_type is AES256."

    }

  }

  rule {

    ##########################################################################
    # Block SSE-C uploads
    ##########################################################################

    blocked_encryption_types = ["SSE-C"]

    ##########################################################################
    # Amazon S3 Bucket Keys
    ##########################################################################

    bucket_key_enabled = (
      var.encryption_type == "aws:kms"
      ? var.bucket_key_enabled
      : false
    )

    ##########################################################################
    # Default Encryption
    ##########################################################################

    apply_server_side_encryption_by_default {

      sse_algorithm = var.encryption_type

      kms_master_key_id = (

        var.encryption_type == "AES256"

        ? null

        : (

          var.kms_key_type == "CUSTOMER_MANAGED"

          ? data.aws_kms_key.customer[0].arn

          : null

        )

      )

    }

  }

  depends_on = [
    aws_s3_bucket.this
  ]

}


##############################################################################
# Bucket Versioning Configuration
##############################################################################

resource "aws_s3_bucket_versioning" "this" {

  bucket = aws_s3_bucket.this.id

  versioning_configuration {

    status = (
      var.enable_versioning
      ? "Enabled"
      : "Suspended"
    )

  }

  depends_on = [
    aws_s3_bucket.this
  ]

}


##############################################################################
# Ownership Controls Configuration
##############################################################################

resource "aws_s3_bucket_ownership_controls" "this" {

  bucket = aws_s3_bucket.this.id

  rule {

    object_ownership = var.object_ownership

  }

  depends_on = [
    aws_s3_bucket.this
  ]

}


##############################################################################
# Public Access Block Configuration
##############################################################################

resource "aws_s3_bucket_public_access_block" "this" {

  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets

  depends_on = [
    aws_s3_bucket.this
  ]

}

##############################################################################
# Static Website Configuration
##############################################################################

resource "aws_s3_bucket_website_configuration" "this" {

  count = (

    var.static_website_type != null ?

    1 :

    0

  )


  bucket = aws_s3_bucket.this.id


  ###########################################################################
  # Validations
  ###########################################################################

  lifecycle {


    #########################################################################
    # Website Hosting Validation
    #########################################################################

    precondition {

      condition = (

        var.static_website_type == null ||

        var.static_website_type == "redirect" ||

        (

          var.static_website_type == "website" &&

          try(

            length(

              trimspace(
                var.website_index_document
              )

            ) > 0,

            false

          )

        )

      )

      error_message = "website_index_document must be provided when static_website_type is website."

    }


    #########################################################################
    # Redirect Hosting Validation
    #########################################################################

    precondition {

      condition = (

        var.static_website_type == null ||

        var.static_website_type == "website" ||

        (

          var.static_website_type == "redirect" &&

          try(

            length(

              trimspace(
                var.redirect_host_name
              )

            ) > 0,

            false

          )

        )

      )

      error_message = "redirect_host_name must be provided when static_website_type is redirect."

    }


    #########################################################################
    # Mutual Exclusivity Validation
    #########################################################################

    precondition {

      condition = (

        var.static_website_type == null ||

        (

          var.static_website_type == "website" &&

          var.redirect_host_name == null &&

          var.redirect_protocol == null

        )

        ||

        (

          var.static_website_type == "redirect" &&

          var.website_index_document == null &&

          var.website_error_document == null

        )

      )

      error_message = "Only one hosting type can be configured. Either website or redirect."

    }

  }


  ###########################################################################
  # Website Hosting
  ###########################################################################

  dynamic "index_document" {

    for_each = (

      var.static_website_type == "website"

    ) ? [1] : []


    content {

      suffix = var.website_index_document

    }

  }



  dynamic "error_document" {

    for_each = (

      var.static_website_type == "website" &&

      try(

        length(

          trimspace(
            var.website_error_document
          )

        ) > 0,

        false

      )

    ) ? [1] : []


    content {

      key = var.website_error_document

    }

  }



  ###########################################################################
  # Redirect Hosting
  ###########################################################################

  dynamic "redirect_all_requests_to" {

    for_each = (

      var.static_website_type == "redirect"

    ) ? [1] : []


    content {

      host_name = var.redirect_host_name

      protocol = var.redirect_protocol

    }

  }


  ###########################################################################
  # Dependencies
  ###########################################################################

  depends_on = [

    aws_s3_bucket.this

  ]

}

##############################################################################
# Event Notification Configuration
##############################################################################

resource "aws_s3_bucket_notification" "this" {

  count = (

    var.enable_event_notifications ||
    var.enable_eventbridge_notifications
  ) ? 1 : 0

  bucket = aws_s3_bucket.this.id
  ###########################################################################
  # Validations
  ###########################################################################

  lifecycle {

    precondition {

      condition = (

        var.enable_event_notifications == false ?

        true :

        length(var.event_notifications) > 0

      )

      error_message = "At least one event notification configuration must be provided."

    }

  }

  ##############################################################################
  # Amazon EventBridge Notifications
  ##############################################################################

  eventbridge = var.enable_eventbridge_notifications

  ###########################################################################
  # SNS Notifications
  ###########################################################################

  dynamic "topic" {

    for_each = {

      for index, notification in var.event_notifications :

      index => notification

      if lower(notification.destination_type) == "sns"

    }
    content {

      topic_arn = topic.value.destination_arn

      events = topic.value.events

      filter_prefix = try(
        topic.value.filter_prefix,
        null
      )

      filter_suffix = try(
        topic.value.filter_suffix,
        null
      )

    }

  }
  ###########################################################################
  # SQS Notifications
  ###########################################################################

  dynamic "queue" {

    for_each = {

      for index, notification in var.event_notifications :

      index => notification

      if lower(notification.destination_type) == "sqs"

    }
    content {

      queue_arn = queue.value.destination_arn

      events = queue.value.events

      filter_prefix = try(
        queue.value.filter_prefix,
        null
      )

      filter_suffix = try(
        queue.value.filter_suffix,
        null
      )

    }

  }

  ###########################################################################
  # Lambda Notifications
  ###########################################################################

  dynamic "lambda_function" {

    for_each = {

      for index, notification in var.event_notifications :

      index => notification

      if lower(notification.destination_type) == "lambda"

    }
    content {

      lambda_function_arn = lambda_function.value.destination_arn

      events = lambda_function.value.events

      filter_prefix = try(
        lambda_function.value.filter_prefix,
        null
      )

      filter_suffix = try(
        lambda_function.value.filter_suffix,
        null
      )

    }

  }
  depends_on = [

    aws_s3_bucket.this,
    aws_s3_bucket_versioning.this,
    aws_lambda_permission.s3_notification,
    terraform_data.sqs_permission,
    terraform_data.sns_permission
  ]
}

##############################################################################
# Lambda Permissions
##############################################################################

resource "aws_lambda_permission" "s3_notification" {

  for_each = {

    for index, notification in var.event_notifications :

    index => notification

    if(
      var.enable_event_notifications &&
      lower(notification.destination_type) == "lambda" &&
      try(notification.manage_permission, true)
    )

  }

  statement_id = format(
    "AllowExecutionFromS3-%s",
    replace(aws_s3_bucket.this.bucket, ".", "-")
  )

  action = "lambda:InvokeFunction"

  function_name = each.value.destination_arn

  principal = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.this.arn

}

resource "terraform_data" "sqs_permission" {

  for_each = {

    for idx, notification in var.event_notifications :

    idx => notification

    if lower(notification.destination_type) == "sqs"

    && try(notification.manage_permission, true)

  }

  triggers_replace = {

    bucket_name = aws_s3_bucket.this.bucket

    bucket_arn = aws_s3_bucket.this.arn

    queue_arn = each.value.destination_arn

  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "& ${var.python_command} '${abspath(path.module)}/scripts/merge_sqs_policy.py' --bucket-name '${aws_s3_bucket.this.bucket}' --bucket-arn '${aws_s3_bucket.this.arn}' --queue-arn '${each.value.destination_arn}' --region '${data.aws_region.current.region}'"
  }

}

resource "terraform_data" "sns_permission" {

  for_each = {
    for idx, notification in var.event_notifications :
    idx => notification

    if lower(notification.destination_type) == "sns"
    && try(notification.manage_permission, true)
  }

  triggers_replace = {
    bucket_name = aws_s3_bucket.this.bucket
    bucket_arn  = aws_s3_bucket.this.arn
    topic_arn   = each.value.destination_arn
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "& ${var.python_command} '${abspath(path.module)}/scripts/merge_sns_policy.py' --bucket-name '${aws_s3_bucket.this.bucket}' --bucket-arn '${aws_s3_bucket.this.arn}' --topic-arn '${each.value.destination_arn}' --region '${data.aws_region.current.region}'"
  }
}

##############################################################################
# Transfer Acceleration Configuration
##############################################################################

resource "aws_s3_bucket_accelerate_configuration" "this" {

  count = (
    var.enable_transfer_acceleration
    ? 1
    : 0
  )

  bucket = aws_s3_bucket.this.id

  status = (
    var.enable_transfer_acceleration
    ? "Enabled"
    : "Suspended"
  )

  depends_on = [
    aws_s3_bucket.this
  ]

}


##############################################################################
# Requester Pays Configuration
##############################################################################

resource "aws_s3_bucket_request_payment_configuration" "this" {

  count = (
    var.enable_requester_pays
    ? 1
    : 0
  )

  bucket = aws_s3_bucket.this.id

  payer = (
    var.enable_requester_pays
    ? "Requester"
    : "BucketOwner"
  )

  depends_on = [
    aws_s3_bucket.this
  ]

}

##############################################################################
# Object Lock Configuration
##############################################################################

resource "aws_s3_bucket_object_lock_configuration" "this" {

  count = (
    var.enable_object_lock
    ? 1
    : 0
  )

  bucket = aws_s3_bucket.this.id

  lifecycle {

    precondition {

      condition = (
        var.enable_object_lock == false ||
        (
          var.object_lock_days != null &&
          var.object_lock_days > 0
        )
      )

      error_message = "object_lock_days must be greater than zero when Object Lock is enabled."

    }

  }

  rule {

    default_retention {

      mode = var.object_lock_mode

      days = var.object_lock_days

    }

  }

  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_versioning.this
  ]

}
