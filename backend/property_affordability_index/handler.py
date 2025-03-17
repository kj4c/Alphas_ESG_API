import json
from helpers import find_property_price_index

def lambda_handler(event, context):
    """
    Lambda function entry point.
    @event:
    @context:
    @return:
    """

    try:
        body = event.get("body")
        if not body:
            raise ValueError("Missing 'body' in event")

        if isinstance(body, str):
            data = json.loads(body)
            if isinstance(data, str):
                data = json.loads(data)
        elif isinstance(body, dict):
            data = body
        else:
            raise ValueError("Unrecognized body format")
        
        print("DEBUG Raw body:", body)
        print("DEBUG Parsed data:", data)
        print("DEBUG Type of data:", type(data))

        if "id" not in data:
            raise ValueError("Missing 'id' in body")
        
        
        data_id= json.loads(event["body"])
        property_price_index = find_property_price_index(data['id'])
        return {
            "statusCode": 200,
            "body": json.dumps({
            "property_price_index": property_price_index
            })
        }
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(e)})
        }
