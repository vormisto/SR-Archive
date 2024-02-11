import json
import requests
import boto3
import os
import logging
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

dynamodb_client = boto3.client('dynamodb', region_name=os.environ['region'])
domain = os.environ['domain']
logger = logging.getLogger(__name__)

# Function to get new listings
def fetch_url(typeListing, page):
    # Used to calculate the possible offset if we want to request other than the first page (24 listings are returned on one request)
    offset = page * 24

    # Lets save our cookies and the user-agent
    s = requests.Session()
    s.headers.update({'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/118.0'})

    # This request needs to be made to get cuid, loaded and token. Those are needed as headers when querying API
    try:
        response = s.get('https://%s/user/get?format=json&rand=924' % (domain))
    except Exception as e:
        logger.error(f'An error occurred: {e}')
        return None
    
    # Init values
    cuid = response.json()['user']['cuid']
    loaded = response.json()['user']['time']
    token = response.json()['user']['token']

    # Set the required headers for API call
    s.headers.update({'OTA-cuid': cuid})
    s.headers.update({'OTA-loaded': str(loaded)})
    s.headers.update({'OTA-token': token})

    # Generate the URL based on listing type and offset
    if typeListing == "RENT":
        URL = "https://%s/api/search?cardType=101&limit=24&offset=%s&price[min]=300&size[min]=5&sortBy=published_sort_desc" % (domain, str(offset))
    else:
        URL = "https://%s/api/search?buildingType[]=1&buildingType[]=256&buildingType[]=2&buildingType[]=64&buildingType[]=4&buildingType[]=32&buildingType[]=512&cardType=100&habitationType[]=1&limit=24&offset=%s&price[min]=35000&size[min]=10&constructionYear[max]=2030&constructionYear[min]=1800&sortBy=published_sort_desc" % (domain, str(offset))

    # Request the data from API
    try:
        apartments = s.get(URL).json()
    # Log possible errors
    except Exception as e:
        logger.error(f'An error occurred: {e}')
        return None
    else:
        # Return data if no errors were encountered
        return apartments

# Function to organize listing retrieval
def get_new_apartments(typeListing):
    # List for new apartments to save to
    listNewApartments = []

    # Used for listing pagination handling
    page = 0

    while True:
        # Date 30mins ago (last time this lambda was run)
        lastRunTime = datetime.now()  - timedelta(hours=0, minutes=30)

        # Get listings
        apartments = fetch_url(typeListing, page)

        # Used to count new listings
        countNew = 0

        # Lets loop the apartments and see if there are any new ones
        for apartment in apartments["cards"]:
            publishedTime = datetime.strptime(apartment["meta"]["published"], '%Y-%m-%d %H:%M:%S')

            # See if listing was posted after the last run
            if publishedTime > lastRunTime:
                # Init the values
                city = apartment["location"]["city"] if apartment["location"]["city"] is not None else ' '
                district = apartment["location"]["district"] if apartment["location"]["district"] is not None else ' '
                price = apartment["data"]["price"].split("€")[0].replace(u'\xa0', u'') if apartment["data"]["price"] is not None else '0'
                size = apartment["data"]["size"].split(" ")[0].replace(',', '.') if apartment["data"]["size"] is not None else '0'
                buildYear = apartment["data"]["buildYear"] if apartment["data"]["buildYear"] is not None else '0'
                roomConfiguration = apartment["data"]["roomConfiguration"] if apartment["data"]["roomConfiguration"] is not None else ' '
                aptFloor = apartment["data"]["floor"] if apartment["data"]["floor"] is not None else '1'
                buildingFloor = apartment["data"]["buildingFloorCount"] if apartment["data"]["buildingFloorCount"] is not None else '1'
                floor = str(aptFloor) + "/" + str(buildingFloor)
                address = apartment["location"]["address"] if apartment["location"]["address"] is not None else ' '
                published = apartment["meta"]["published"] if apartment["meta"]["published"] is not None else ' '
                listingId = apartment["cardId"]
                cityId = city.capitalize() + "#" + str(listingId)

                # Add the listing to list
                listNewApartments.append([typeListing, cityId, district, address, published, buildYear, floor, price, roomConfiguration, size])

                # Add one to counter
                countNew += 1

        # 24 item per page, stop if less than 24 new ones, continue to next page if more
        if countNew < 24:
            break

        # Add one so we can next request the next page
        page += 1

    # Return list of new listings
    return listNewApartments
        
# Function used to save one listing to dynamodb
def put_item(typeListing, cityId, district, address, publishedDate, buildYear, floor, price, roomConfiguration, size):
    # Used for logging
    print([typeListing, cityId, district, address, publishedDate, buildYear, floor, price, roomConfiguration, size])

    # Try to put item to dynamodb
    try:
        dynamodb_client.put_item(
            TableName=os.environ['table_name'],
            Item={
                'type': {"S": typeListing + "#1"},
                'cityId': {"S": cityId},
                'district': {"S": district},
                'address': {"S": address},
                'publishedDate': {"S": publishedDate},
                'buildYear': {"N": str(buildYear)},
                'floor': {"S": floor},
                'price': {"N": str(price)},
                'roomConfiguration': {"S": roomConfiguration},
                'size': {"N": str(size)}
            }
        )
    # Log error if encountered
    except ClientError as e:
        logger.error(e)
        logger.error([typeListing, cityId, district, address, publishedDate, buildYear, floor, price, roomConfiguration, size])

# Function used to organize listing saving
def save_data(apartments):
    # Lets loop the apartments
    for apartment in apartments:
        # Init values
        typeListing = apartment[0]
        cityId = apartment[1]
        district = apartment[2]
        address = apartment[3]
        publishedDate = apartment[4]
        buildYear = apartment[5]
        floor = apartment[6]
        price = apartment[7]
        roomConfiguration = apartment[8]
        size = apartment[9]

        # Put item to dynamodb
        put_item(typeListing, cityId, district, address, publishedDate, buildYear, floor, price, roomConfiguration, size)

# Function called by EventBridge
def lambda_handler(event, context):
    # Get listings by type
    sellingListings = get_new_apartments("SELL")
    rentingListings = get_new_apartments("RENT")

    # Save new listings to dynamodb
    save_data(sellingListings)
    save_data(rentingListings)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Done')
    }