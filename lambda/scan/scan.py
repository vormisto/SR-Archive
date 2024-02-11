import boto3
import os
import json
import logging
from decimal import Decimal
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb', region_name=os.environ['region'])
table = dynamodb.Table(os.environ['table_name'])
index = os.environ['GSI']
sqs = boto3.resource('sqs')
queue = sqs.Queue(os.environ['queue_url'])
logger = logging.getLogger(__name__)

# https://stackoverflow.com/a/51877011
def handle_decimal_type(obj):
  if isinstance(obj, Decimal):
      if float(obj).is_integer():
         return int(obj)
      else:
         return float(obj)
  raise TypeError

# Get all item from GSI by listing type
def query_table(type_value):
    # List used for item storage
    data = []

    # Try to query data from GSI
    try:
        response = table.query(IndexName=index, KeyConditionExpression=boto3.dynamodb.conditions.Key('type').eq(type_value))

        # Save items to "data" list
        data.extend(response['Items'])

        # If there was too much data for one request
        while 'LastEvaluatedKey' in response:
            response = table.query(IndexName=index, KeyConditionExpression=boto3.dynamodb.conditions.Key('type').eq(type_value), ExclusiveStartKey=response['LastEvaluatedKey'])

            # Save additional items to "data" list
            data.extend(response['Items'])

    # Log possible errors
    except ClientError as e:
        logger.error(e)

    # Return all items
    return data

# Send listings to SQS
def send_to_queue(batch):
    try:
        queue.send_message(MessageBody=json.dumps(batch, default=handle_decimal_type))
    except ClientError as e:
        logger.error(e)

# Function called by EventBridge
def lambda_handler(event, context):
    # First get all "selling" listings
    apartmentsSelling = query_table("SELL#1")
    # Divide the items to patches
    batchesSelling = [apartmentsSelling[x:x+300] for x in range(0, len(apartmentsSelling), 300)]
    for batch in batchesSelling:
        # Send each patch to SQS
        send_to_queue(batch)

    # Same things for "renting" listings
    apartmentsRenting = query_table("RENT#1")
    batchesRenting = [apartmentsRenting[x:x+300] for x in range(0, len(apartmentsRenting), 300)]
    for batch in batchesRenting:
        send_to_queue(batch)