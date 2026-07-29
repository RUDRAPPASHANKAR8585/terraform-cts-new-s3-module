# =====================================================================
# Dev Assume Role Script - Windows PowerShell
# Equivalent to dev_assume_role.sh
# =====================================================================

# ---------------------------------------------------------------------
# STEP 1 - Base temporary credentials
# Paste the temporary credentials you receive here
# ---------------------------------------------------------------------

$env:AWS_ACCESS_KEY_ID     = "PASTE_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "PASTE_SECRET_ACCESS_KEY"
$env:AWS_SESSION_TOKEN     = "PASTE_SESSION_TOKEN"

# Optional
$env:AWS_DEFAULT_REGION = "eu-west-1"

Write-Host ""
Write-Host "Base credentials configured." -ForegroundColor Green

# ---------------------------------------------------------------------
# STEP 2 - Assume Role
# ---------------------------------------------------------------------

$RoleArn = "arn:aws:iam::499998932841:role/RIDY_AWS_RDRAR27_APPADMV1"
$SessionName = "APPADMV1"

Write-Host ""
Write-Host "Assuming role..." -ForegroundColor Yellow

$OUT = aws sts assume-role `
    --role-arn $RoleArn `
    --role-session-name $SessionName | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Failed to assume role." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------
# STEP 3 - Replace current credentials
# ---------------------------------------------------------------------

$env:AWS_ACCESS_KEY_ID     = $OUT.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $OUT.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $OUT.Credentials.SessionToken

Write-Host ""
Write-Host "Role assumed successfully." -ForegroundColor Green

# ---------------------------------------------------------------------
# STEP 4 - Verify identity
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "Current AWS Identity" -ForegroundColor Cyan
aws sts get-caller-identity

Write-Host ""
Write-Host "Environment variables are ready." -ForegroundColor Green
Write-Host ""
Write-Host "Now you can run:"
Write-Host "terraform init"
Write-Host "terraform plan"
Write-Host "terraform apply"
