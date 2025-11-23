import os
import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DDB_TABLE")
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    # SQS batch -> event["Records"]
    for record in event.get("Records", []):
        body = record.get("body")
        try:
            item = json.loads(body)
        except Exception:
            # If body not JSON, store raw
            item = {"id": record.get("messageId"), "payload": body}

        # Put item in DynamoDB
        table.put_item(Item={
            "id": item.get("id"),
            "payload": json.dumps(item.get("payload"))
        })

    return {"status": "ok"}
