import json


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    print("Validating data for model training...")

    # Умовна логіка валідації
    source = event.get('source', 'unknown')

    return {
        'status': 'validated',
        'source': source,
        'message': 'Data validation successful'
    }