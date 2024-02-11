import requests
import boto3
import json
import logging
import time
import re
import os
from datetime import datetime
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb', region_name=os.environ['region'])
table = dynamodb.Table(os.environ['table_name'])
domain = os.environ['domain']
logger = logging.getLogger(__name__)

# Simple wrapper for requests head
def request_head(url):
    response = 0
    try:
        response = requests.head(url)
    except requests.exceptions.RequestException as e:
        logger.error(e)
    return response

# Simple wrapper for requests get
def request_get(url):
    response = 0
    try:
        response = requests.get(url)
    except requests.exceptions.RequestException as e:
        logger.error(e)
    return response

# Used to check the availability
def check_availability(apartment):
    # Init the values
    city, listingId = apartment['cityId'].split('#')
    listingType = apartment['type'].split('#')[0]

    # Generate the URL based on listing type
    if listingType == 'SELL':
        url = 'https://%s/myytavat-asunnot/%s/%d' % (domain, city.lower(), int(listingId))
    elif listingType == 'RENT':
        url = 'https://%s/vuokra-asunnot/%s/%d' % (domain, city.lower(), int(listingId))
    else:
        logger.error('No listing type.')
        exit(0)

    # Use head method to request the URL
    response = request_head(url)
    if response != 0:
        # If we get HTTP code 410, return 0 to indicate that listing has been removed
        if response.status_code == 410:
            return 0
        # If the generated URL was wrong make the head request again for the correct URL
        elif response.status_code == 301:
            url = 'https://%s%s' % (domain, response.headers['Location'])
            response = request_head(url)
            if response != 0:
                if response.status_code == 410:
                    return 0
                
    # If we got here the listing appears to be still active
    return 1

# Get data for one listing from dynamodb
def get_data(apartment):
    try:
        response = table.get_item(Key={'type': apartment['type'], 'cityId': apartment['cityId']})
    except ClientError as e:
        logger.error(e)
    return response["Item"]

# Remove one listing from dynamodb
def remove_data(apartment):
    print("Removing: ", apartment)
    try:
        table.delete_item(Key={'type': apartment['type'], 'cityId': apartment['cityId']})
    except ClientError as e:
        logger.error(e) 

# Make get request to removed listing page to retrieve the deletion date
def get_removal_date(apartment):
    # Init values
    city, listingId = apartment['cityId'].split('#')
    listingType = apartment['type'].split('#')[0]

    # Generate the URL based on listing type
    if listingType == 'SELL':
        url = 'https://%s/myytavat-asunnot/%s/%d' % (domain, city.lower(), int(listingId))
    elif listingType == 'RENT':
        url = 'https://%s/vuokra-asunnot/%s/%d' % (domain, city.lower(), int(listingId))

    # Make the get request
    response = request_get(url)

    # If the generated URL was wrong let's make a new one to correct path
    if response.status_code == 301:
        url = 'https://%s%s' % (domain, response.headers['Location'])
        response = request_get(url)

    # Use regex to search for the removal date. Couple different regex because the string is different if the listing was removed the same day it was posted
    multi_date = re.search(r' \- ([0-9]+(\.[0-9]+)+)\.</div>', response.text)
    single_date = re.search(r'Ilmoitus on ollut (\w+) ([0-9]+(\.[0-9]+)+)\.', response.text)

    # Format the date correctly
    if multi_date:
        removal_date = datetime.strptime(multi_date.group(1), '%d.%m.%Y').strftime('%Y-%m-%d')
    elif single_date:
        removal_date = datetime.strptime(single_date.group(2), '%d.%m.%Y').strftime('%Y-%m-%d')
    else:
        removal_date = datetime.today().strftime('%Y-%m-%d')

    # Return the date listing was removed
    return removal_date

# Add one listing to dynamodb
def add_data(apartment):
    # Get the date listing was removed
    removed = get_removal_date(apartment)

    # Init values
    city, listingId = apartment['cityId'].split('#')
    listingType = apartment['type'].split('#')[0]

    # Construct the item in correct format
    item = {
        "type": listingType + "#0",
        "cityId": city + "#" + removed + "#" + listingId,
        "district": apartment["district"],
        "roomConfiguration": apartment["roomConfiguration"],
        "address": apartment["address"],
        "buildYear": str(apartment["buildYear"]),
        "size": str(apartment["size"]),
        "price": str(apartment["price"]),
        "floor": apartment["floor"],
        "publishedDate": apartment["publishedDate"]
    }
    # Try to put item to dynamodb
    try:
        response = table.put_item(Item=item)
        return 1
    # Log error and return 0 if put was not successful
    except ClientError as e:
        logger.error(e)
        return 0

# Function that is called by SQS
def lambda_handler(event, context):
    # Save input listing data to messages
    messages = json.loads(event['Records'][0]['body'])

    # Loop through all listings one by one
    for apartment in messages:
        # First check if the listing is still active
        available = check_availability(apartment)

        # If listing has been removed
        if not available:
            # Get full listing data from dynamodb
            old_data = get_data(apartment)

            # Add the listing to dynamodb as removed
            if add_data(old_data):
                # If the listing was successfully added as removed we can remove the old copy from dynamodb
                remove_data(apartment)