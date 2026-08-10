# ==========================================
# AWS Assume Role Script
# ==========================================

# Initial temporary credentials
$env:AWS_ACCESS_KEY_ID = "<ACCESS_KEY_ID>"
$env:AWS_SECRET_ACCESS_KEY = "<SECRET_ACCESS_KEY>"
$env:AWS_SESSION_TOKEN = "<SESSION_TOKEN>"

# Target IAM Role
$ROLE_ARN = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"

# Session name
$SESSION_NAME = "APPADMVI"

Write-Host "Assuming IAM role..." -ForegroundColor Cyan

# Assume role
$OUT = aws sts assume-role `
    --role-arn $ROLE_ARN `
    --role-session-name $SESSION_NAME |
    ConvertFrom-Json

# Check whether assume-role succeeded
if (-not $OUT.Credentials) {
    Write-Host "Failed to assume IAM role." -ForegroundColor Red
    exit 1
}

# Set assumed-role credentials
$env:AWS_ACCESS_KEY_ID = $OUT.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $OUT.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $OUT.Credentials.SessionToken

Write-Host "Role assumed successfully." -ForegroundColor Green

# Verify identity
Write-Host "Current AWS identity:" -ForegroundColor Cyan
aws sts get-caller-identity
