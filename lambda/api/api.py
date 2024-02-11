import json
import boto3
import logging
import os
from decimal import Decimal
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from datetime import datetime, timedelta, time

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['table_name'])
scan_hour = int(os.environ['scan_hour'])
logger = logging.getLogger(__name__)

# https://stackoverflow.com/a/51877011
def handle_decimal_type(obj):
  if isinstance(obj, Decimal):
      if float(obj).is_integer():
         return int(obj)
      else:
         return float(obj)
  raise TypeError

# This function will calculate the next time for scan, will be used for caching
def next_update():
    now = datetime.utcnow()
    next = datetime.combine(now.date(), time(scan_hour+1, 0))
    if now.time() > time(scan_hour+1, 0):
        next += timedelta(days=1)
    return next

# Function that is called by APIGW
def lambda_handler(event, context):
    # Init the values, format correctly so they can be used to query dynamodb
    cityFrom = event["queryStringParameters"].get("city").capitalize() + "#" + event["queryStringParameters"].get("from")
    cityTo = event["queryStringParameters"].get("city").capitalize() + "#" + event["queryStringParameters"].get("to")
    listingType = event["queryStringParameters"].get("type") + "#0"
    try:
        # Query dynamodb
        response = table.query(KeyConditionExpression=Key('type').eq(listingType) & Key('cityId').between(cityFrom, cityTo), ScanIndexForward=False)

        # Transform the data to frendlier format so it can be returned to user
        for item in response["Items"]:
            city, removed, listingId = item["cityId"].split("#")
            listingType = item["type"].split("#")[0]
            del item["type"]
            del item["cityId"]
            item["type"] = listingType
            item["city"] = city
            item["removedDate"] = removed
            item["id"] = listingId

        # Expire time will be used as "Expires" header to cache the data in CloudFront
        expire_time = next_update()
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Expires': expire_time.strftime('%a, %d %b %Y %H:%M:%S GMT')
            },
            'body': json.dumps(response['Items'], default=handle_decimal_type)
        }
    # If we get error let the user know there was error
    except ClientError as e:
        logger.error(e) 
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Cache-Control': 'max-age=60'
            },
            'body': json.dumps({'error':'Backend error occured. Unable to retrieve data.'})
        }