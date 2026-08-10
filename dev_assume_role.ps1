# Temporary AWS credentials
$aws_session_token = "<ACTUAL_SESSION_TOKEN>"
$aws_secret_access_key = "<ACTUAL_SECRET_ACCESS_KEY>"
$aws_access_key_id = "<ACTUAL_ACCESS_KEY_ID>"

# Set initial credentials
$env:AWS_ACCESS_KEY_ID = $aws_access_key_id
$env:AWS_SECRET_ACCESS_KEY = $aws_secret_access_key
$env:AWS_SESSION_TOKEN = $aws_session_token

# Role to assume
$ARN = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"
$ROLE = "--role-session-name APPADMVI"

# Assume the IAM role
$OUT = aws sts assume-role --role-arn $ARN $ROLE | ConvertFrom-Json

# Extract temporary credentials
$env:AWS_ACCESS_KEY_ID = $OUT.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $OUT.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $OUT.Credentials.SessionToken

# Verify assumed role
aws sts get-caller-identity
