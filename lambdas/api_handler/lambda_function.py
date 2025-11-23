import os
import json
import uuid
import boto3

sqs = boto3.client("sqs")
SQS_URL = os.environ.get("SQS_URL")

def lambda_handler(event, context):
    # Expecting JSON body
    try:
        body = json.loads(event.get("body") or "{}")
    except Exception:
        body = {}

    item = {
        "id": str(uuid.uuid4()),
        "payload": body
    }

    # Send to SQS as a JSON string
    sqs.send_message(
        QueueUrl=SQS_URL,
        MessageBody=json.dumps(item)
    )

    return {
        "statusCode": 202,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "accepted", "id": item["id"]})
    }
