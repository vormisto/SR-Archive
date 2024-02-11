import base64
import gzip
import json
import os
import boto3
import logging
from botocore.exceptions import ClientError

# Source: https://aws.amazon.com/blogs/mt/get-notified-specific-lambda-function-error-patterns-using-cloudwatch/

sqs = boto3.resource('sqs')
queue = sqs.Queue(os.environ['queue_url'])
logger = logging.getLogger(__name__)

def logpayload(event):
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_payload = json.loads(uncompressed_payload)
    return log_payload

def error_details(payload):
    error_msg = []
    log_events = payload['logEvents']
    loggroup = payload['logGroup']
    logstream = payload['logStream']
    lambda_func_name = loggroup.split('/')[3]
    for log_event in log_events:
        error_msg.append(log_event['message'])
    return loggroup, logstream, error_msg, lambda_func_name

def send_to_queue(message):
    try:
        queue.send_message(MessageBody=json.dumps(message))
    except ClientError as e:
        logger.error(e)

def push_message_to_sqs(loggroup, logstream, error_msg, lambda_func_name):
    new_error = {
        "Function": str(lambda_func_name),
        "LogGroup Name": str(loggroup),
        "LogStream": str(logstream),
        "Log Message(s)": error_msg
    }
    send_to_queue(new_error)

def lambda_handler(event, context):
    pload = logpayload(event)
    lgroup, lstream, errmessage, lambda_func_name = error_details(pload)
    push_message_to_sqs(lgroup, lstream, errmessage, lambda_func_name)