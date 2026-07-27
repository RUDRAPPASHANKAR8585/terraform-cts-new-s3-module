data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

##############################################################################
# Customer Managed KMS Key Lookup
##############################################################################

data "aws_kms_key" "customer" {

  count = (
    var.kms_key_type == "CUSTOMER_MANAGED"
    &&
    local.kms_key_alias != null
  ) ? 1 : 0

  key_id = local.kms_key_alias

}