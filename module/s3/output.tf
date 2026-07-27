###############################################################
# Bucket ID
###############################################################

output "bucket_id" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.id
}

###############################################################
# Bucket ARN
###############################################################

output "bucket_arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}

###############################################################
# Bucket Region
###############################################################

output "bucket_region" {
  description = "AWS Region."
  value       = aws_s3_bucket.this.bucket_region
}

###############################################################
# Bucket Domain Name
###############################################################

output "bucket_domain_name" {
  description = "Bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

###############################################################
# Regional Domain Name
###############################################################

output "bucket_regional_domain_name" {
  description = "Regional domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

###############################################################
# Hosted Zone ID
###############################################################

output "hosted_zone_id" {
  description = "Hosted Zone ID."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "bucket_tags" {

  value = aws_s3_bucket.this.tags_all

}

output "bucket_name" {

  value = aws_s3_bucket.this.bucket

}
