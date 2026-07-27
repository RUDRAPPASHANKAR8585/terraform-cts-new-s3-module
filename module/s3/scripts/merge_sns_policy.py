#!/usr/bin/env python3

"""
merge_sns_policy.py

Merges an S3 Publish permission into an existing SNS Topic Policy.
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
        description="Merge S3 permission into an SNS Topic Policy."
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
        "--topic-arn",
        required=True,
        help="SNS Topic ARN"
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

def parse_topic_arn(topic_arn):
    """
    Parse an SNS Topic ARN.

    Example:
        arn:aws:sns:ap-south-1:700030738273:my-topic
    """

    parts = topic_arn.split(":")

    if len(parts) != 6:
        raise ValueError(f"Invalid Topic ARN: {topic_arn}")

    return {
        "partition": parts[1],
        "service": parts[2],
        "region": parts[3],
        "account_id": parts[4],
        "topic_name": parts[5]
    }


def create_sns_client(region):
    """
    Create an SNS boto3 client.
    """

    logger.info("Creating SNS client...")

    return boto3.client(
        "sns",
        region_name=region
    )


def get_topic_policy(client, topic_arn):
    """
    Retrieve the current SNS policy.

    Returns:
        dict: SNS policy
    """

    logger.info("Retrieving topic policy...")

    response = client.get_topic_attributes(
        TopicArn=topic_arn
    )

    attributes = response.get("Attributes", {})

    policy_json = attributes.get("Policy")

    if not policy_json:

        logger.info("No SNS policy found. Creating a new empty policy.")

        return {
            "Version": "2012-10-17",
            "Statement": []
        }

    logger.info("Existing SNS topic policy found.")

    return json.loads(policy_json)


def build_s3_statement(bucket_name, bucket_arn, topic_arn, account_id):
    """
    Build the S3 -> SNS permission statement.
    """

    return {
        "Sid": f"AllowExecutionFromS3-{bucket_name}",
        "Effect": "Allow",
        "Principal": {
            "Service": "s3.amazonaws.com"
        },
        "Action": "SNS:Publish",
        "Resource": topic_arn,
        "Condition": {
            "ArnEquals": {
                "aws:SourceArn": bucket_arn
            },
            "StringEquals": {
                "aws:SourceAccount": account_id
            }
        }
    }

def statement_exists(policy, bucket_arn, topic_arn):
    """
    Check whether the S3 permission already exists.
    """

    for statement in policy.get("Statement", []):

        if (
            statement.get("Principal") == {"Service": "s3.amazonaws.com"}
            and statement.get("Action") == "SNS:Publish"
            and statement.get("Resource") == topic_arn
            and statement.get("Condition", {})
                .get("ArnEquals", {})
                .get("aws:SourceArn") == bucket_arn
        ):
            return True

    return False

def update_topic_policy(client, topic_arn, policy):
    """
    Update the SNS topic policy.
    """

    logger.info("Updating SNS topic policy...")

    client.set_topic_attributes(
    TopicArn=topic_arn,
    AttributeName="Policy",
    AttributeValue=json.dumps(policy)
   )

    logger.info("Topic policy updated successfully.")

def merge_policy(policy, statement):
    """
    Append the permission statement to the sns topic policy.
    """

    policy.setdefault("Statement", []).append(statement)

    return policy


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main():

    args = parse_arguments()

    logger.info("Starting merge_sns_policy.py")

    logger.info("Bucket Name : %s", args.bucket_name)
    logger.info("Bucket ARN  : %s", args.bucket_arn)
    logger.info("Topic ARN   : %s", args.topic_arn)

    if args.region:
        logger.info("Region      : %s", args.region)

    logger.info("Dry Run     : %s", args.dry_run)

    logger.info("Argument validation completed successfully.")

    # ---------------------------------------------------------
    # Parse Topic ARN
    # ---------------------------------------------------------

    topic = parse_topic_arn(args.topic_arn)

    logger.info("Topic Name : %s", topic["topic_name"])
    logger.info("Account ID : %s", topic["account_id"])

    # ---------------------------------------------------------
    # Create SNS Client
    # ---------------------------------------------------------

    client = create_sns_client(args.region)

    try:
        policy = get_topic_policy(
            client,
            args.topic_arn
        )

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
            args.topic_arn,
            topic["account_id"]
        )

        # ---------------------------------------------------------
        # Check Existing Permission
        # ---------------------------------------------------------

        policy_changed = False

        if statement_exists(
            policy,
            args.bucket_arn,
            args.topic_arn
        ):

            logger.info("S3 permission already exists.")

        else:

            logger.info("Adding S3 permission to topic policy.")

            merge_policy(
                policy,
                statement
            )

            policy_changed = True

        # ---------------------------------------------------------
        # Dry Run / Update topic Policy
        # ---------------------------------------------------------

        if args.dry_run:

            logger.info("Dry-run enabled. Topic policy will not be updated.")
            logger.info("Merged Topic Policy:")

            print(json.dumps(policy, indent=4))

        elif policy_changed:

            update_topic_policy(
                client,
                args.topic_arn,
                policy
            )

        else:

            logger.info("SNS Topic policy already up-to-date. No changes required.")

    except ClientError as ex:

        logger.error("Unable to access SNS topic.")
        logger.error(ex)

        return 1

    return 0


if __name__ == "__main__":

    try:
        sys.exit(main())

    except Exception as ex:
        logger.exception("Unexpected error: %s", ex)
        sys.exit(1)
