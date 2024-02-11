import json
import os
import boto3
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

sqs = boto3.client('sqs')
sns = boto3.client('sns')

# Get messages from queue
def receive_all_messages(queue_url):
    email_body = ""
    while True:
        # Receive messages from SQS
        try:
            response = sqs.receive_message(QueueUrl=queue_url)
        # Log possible error
        except ClientError as e:
            logger.error(e)

        # Check if any messages were returned
        messages = response.get('Messages', [])
        if not messages:
            print("No more messages in queue.")
            break

        # Process each message
        for message in messages:
            # Format messsage so it's easier to read
            json_message = json.loads(message['Body'])
            email_body += "Function: " + json_message['Function'] + '\n'
            email_body += "LogGroup Name: " + json_message['LogGroup Name'] + '\n'
            email_body += "LogStream: " + json_message['LogStream'] + '\n'
            email_body += "Log Message(s): " + '\n'
            for log_msg in json_message['Log Message(s)']:
                email_body += log_msg + '\n'
            email_body += '#########################################\n'

            # Delete the message from the queue after processing
            try:
                sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=message['ReceiptHandle'])
            # Log the possible error
            except ClientError as e:
                logger.error(e)

    # Return the formatted email alert message
    return email_body

# Send message to SNS
def publish_messages(message, sns_arn):
    # Send
    try:
        sns.publish(TargetArn=sns_arn, Subject=f'Lambda errors', Message=message)
    # Log the possible error
    except ClientError as e:
        logger.error(e)

# Function called by EventBridge
def lambda_handler(event, context):
    # Get messages from SQS
    messages = receive_all_messages(os.environ['queue_url'])

    # Send alert to SNS if there were messages
    if messages:
        publish_messages(messages, os.environ['sns_arn'])