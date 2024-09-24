import json
import boto3

translate = boto3.client(service_name='translate')

def lambda_handler(event, context):

    input_text = event['queryStringParameters']['input_text']

    response = translate.translate_text(
        Text=input_text,
        SourceLanguageCode="ja",
        TargetLanguageCode="en"
    )

    output_text = response.get('TranslatedText')

    return {
        'statusCode': 200,
        'body': json.dumps({
            'output_text': output_text
        }),
        'isBase64Encoded': False,
        'headers': {}
    }