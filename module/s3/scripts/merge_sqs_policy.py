#!/usr/bin/env python3

"""
merge_sqs_policy.py

Merges an S3 SendMessage permission into an existing SQS Queue Policy.

This script is intended to be executed by Terraform using the
terraform_data + local-exec provisioner.
"""

import argparse
import logging
import sys
import boto3
import json

from botocore.exceptions import ClientError

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s"
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------
# Argument Parsing
# ---------------------------------------------------------------------

def parse_arguments():
    """
    Parse command line arguments.
    """

    parser = argparse.ArgumentParser(
        description="Merge S3 permission into an SQS Queue Policy."
    )

    parser.add_argument(
        "--bucket-name",
        required=True,
        help="S3 Bucket Name"
    )

    parser.add_argument(
        "--bucket-arn",
        required=True,
        help="S3 Bucket ARN"
    )

    parser.add_argument(
        "--queue-arn",
        required=True,
        help="SQS Queue ARN"
    )

    parser.add_argument(
        "--region",
        required=False,
        default=None,
        help="AWS Region"
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not update AWS resources."
    )

    return parser.parse_args()

# ---------------------------------------------------------------------
# AWS Helpers
# ---------------------------------------------------------------------

def parse_queue_arn(queue_arn):
    """
    Parse an SQS Queue ARN.

    Example:
        arn:aws:sqs:ap-south-1:700030738273:s3-poc-sqs
    """

    parts = queue_arn.split(":")

    if len(parts) != 6:
        raise ValueError(f"Invalid Queue ARN: {queue_arn}")

    return {
        "partition": parts[1],
        "service": parts[2],
        "region": parts[3],
        "account_id": parts[4],
        "queue_name": parts[5]
    }


def create_sqs_client(region):
    """
    Create an SQS boto3 client.
    """

    logger.info("Creating SQS client...")

    return boto3.client(
        "sqs",
        region_name=region
    )


def get_queue_url(client, queue_name, account_id):
    """
    Resolve Queue URL from Queue Name.
    """

    logger.info("Resolving Queue URL...")

    response = client.get_queue_url(
        QueueName=queue_name,
        QueueOwnerAWSAccountId=account_id
    )

    return response["QueueUrl"]

def get_queue_policy(client, queue_url):
    """
    Retrieve the current SQS queue policy.

    Returns:
        dict: Queue policy
    """

    logger.info("Retrieving queue policy...")

    response = client.get_queue_attributes(
        QueueUrl=queue_url,
        AttributeNames=["Policy"]
    )

    attributes = response.get("Attributes", {})

    policy_json = attributes.get("Policy")

    if not policy_json:

        logger.info("No queue policy found. Creating a new empty policy.")

        return {
            "Version": "2012-10-17",
            "Statement": []
        }

    logger.info("Existing queue policy found.")

    return json.loads(policy_json)


def build_s3_statement(bucket_name, bucket_arn, queue_arn, account_id):
    """
    Build the S3 -> SQS permission statement.
    """

    return {
        "Sid": f"AllowExecutionFromS3-{bucket_name}",
        "Effect": "Allow",
        "Principal": {
            "Service": "s3.amazonaws.com"
        },
        "Action": "SQS:SendMessage",
        "Resource": queue_arn,
        "Condition": {
            "ArnEquals": {
                "aws:SourceArn": bucket_arn
            },
            "StringEquals": {
                "aws:SourceAccount": account_id
            }
        }
    }

def statement_exists(policy, bucket_arn, queue_arn):
    """
    Check whether the S3 permission already exists.
    """

    for statement in policy.get("Statement", []):

        if (
            statement.get("Principal") == {"Service": "s3.amazonaws.com"}
            and statement.get("Action") == "SQS:SendMessage"
            and statement.get("Resource") == queue_arn
            and statement.get("Condition", {})
                .get("ArnEquals", {})
                .get("aws:SourceArn") == bucket_arn
        ):
            return True

    return False

def update_queue_policy(client, queue_url, policy):
    """
    Update the SQS queue policy.
    """

    logger.info("Updating queue policy...")

    client.set_queue_attributes(
        QueueUrl=queue_url,
        Attributes={
            "Policy": json.dumps(policy)
        }
    )

    logger.info("Queue policy updated successfully.")

def merge_policy(policy, statement):
    """
    Append the permission statement to the queue policy.
    """

    policy.setdefault("Statement", []).append(statement)

    return policy


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main():

    args = parse_arguments()

    logger.info("Starting merge_sqs_policy.py")

    logger.info("Bucket Name : %s", args.bucket_name)
    logger.info("Bucket ARN  : %s", args.bucket_arn)
    logger.info("Queue ARN   : %s", args.queue_arn)

    if args.region:
        logger.info("Region      : %s", args.region)

    logger.info("Dry Run     : %s", args.dry_run)

    logger.info("Argument validation completed successfully.")

    # ---------------------------------------------------------
    # Parse Queue ARN
    # ---------------------------------------------------------

    queue = parse_queue_arn(args.queue_arn)

    logger.info("Queue Name : %s", queue["queue_name"])
    logger.info("Account ID : %s", queue["account_id"])

    # ---------------------------------------------------------
    # Create SQS Client
    # ---------------------------------------------------------

    client = create_sqs_client(args.region)

    # ---------------------------------------------------------
    # Resolve Queue URL
    # ---------------------------------------------------------

    try:

        queue_url = get_queue_url(
            client,
            queue["queue_name"],
            queue["account_id"]
        )

        logger.info("Queue URL : %s", queue_url)

        # ---------------------------------------------------------
        # Read Queue Policy
        # ---------------------------------------------------------

        policy = get_queue_policy(client, queue_url)

        logger.info(
            "Policy Version : %s",
            policy.get("Version")
        )

        logger.info(
            "Existing Statements : %d",
            len(policy.get("Statement", []))
        )

        # ---------------------------------------------------------
        # Build S3 Permission
        # ---------------------------------------------------------

        statement = build_s3_statement(
            args.bucket_name,
            args.bucket_arn,
            args.queue_arn,
            queue["account_id"]
        )

        # ---------------------------------------------------------
        # Check Existing Permission
        # ---------------------------------------------------------

        policy_changed = False

        if statement_exists(
            policy,
            args.bucket_arn,
            args.queue_arn
        ):

            logger.info("S3 permission already exists.")

        else:

            logger.info("Adding S3 permission to queue policy.")

            merge_policy(
                policy,
                statement
            )

            policy_changed = True

        # ---------------------------------------------------------
        # Dry Run / Update Queue Policy
        # ---------------------------------------------------------

        if args.dry_run:

            logger.info("Dry-run enabled. Queue policy will not be updated.")
            logger.info("Merged Queue Policy:")

            print(json.dumps(policy, indent=4))

        elif policy_changed:

            update_queue_policy(
                client,
                queue_url,
                policy
            )

        else:

            logger.info("Queue policy already up-to-date. No changes required.")

    except ClientError as ex:

        logger.error("Unable to access SQS queue.")
        logger.error(ex)

        return 1

    return 0


if __name__ == "__main__":

    try:
        sys.exit(main())

    except Exception as ex:
        logger.exception("Unexpected error: %s", ex)
        sys.exit(1)
