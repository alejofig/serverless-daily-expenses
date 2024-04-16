import json
import urllib.parse
import boto3
from constants import prompt
from text_generate import TextPrompt
from sheets import send_to_sheets

s3 = boto3.client('s3')
def lambda_handler(event, context):
    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        obj = response['Body'].read().decode("utf-8")
        response =(TextPrompt.generate(f"{obj} {prompt}"))
        texto_json = response.replace('```', '')
        send_to_sheets(json.loads(texto_json))
        return "Email sent to sheets"
    except Exception as e:
        print(e)
        raise e
