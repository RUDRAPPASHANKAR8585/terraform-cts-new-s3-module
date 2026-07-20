module "s3" {

  source = "./module/s3"

  #################################
  # Bucket Configuration
  #################################

  bucket_name = var.bucket_name

  environment = var.environment

  project = var.project

  application = var.application

  owner = var.owner

  cost_center = var.cost_center

  additional_tags = var.additional_tags

  force_destroy = var.force_destroy

  #################################
  # Encryption
  #################################

  enable_kms_encryption = var.enable_kms_encryption

  kms_key_arn = var.kms_key_arn

  #################################
  # Versioning
  #################################

  enable_versioning = var.enable_versioning

  #################################
  # Ownership Controls
  #################################

  object_ownership = var.object_ownership

  #################################
  # Public Access Block
  #################################

  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets

  #################################
  # Static Website Hosting
  #################################

  static_website_type = var.static_website_type

  website_index_document = var.website_index_document

  website_error_document = var.website_error_document

  redirect_host_name = var.redirect_host_name

  redirect_protocol = var.redirect_protocol

  #################################
  # event_Notifications
  #################################

  enable_event_notifications = var.enable_event_notifications

  event_notifications = var.event_notifications

  enable_eventbridge_notifications = var.enable_eventbridge_notifications


  #################################
  # Transfer Acceleration
  #################################

  enable_transfer_acceleration = var.enable_transfer_acceleration

  #################################
  # Requester Pays
  #################################

  enable_requester_pays = var.enable_requester_pays

  #################################
  # Object Lock
  #################################

  enable_object_lock = var.enable_object_lock

  object_lock_mode = var.object_lock_mode

  object_lock_days = var.object_lock_days

}