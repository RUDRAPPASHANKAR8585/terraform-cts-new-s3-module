locals {

  generated_bucket_name = format(
    "%s-%s-%s",
    var.bucket_name,
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.region
  )

  kms_key_alias = (
    var.kms_key_alias == null
    ? null
    : (
      startswith(var.kms_key_alias, "alias/")
      ? trimspace(var.kms_key_alias)
      : "alias/${trimspace(var.kms_key_alias)}"
    )
  )

}