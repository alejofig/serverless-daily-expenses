from constants import prompt as email_prompt, email_example
import boto3
import json
import os
from dotenv import load_dotenv
load_dotenv()
class TextPrompt(object):

    @staticmethod
    def generate(prompt: str):
        bedrock = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION'))
        payload = {
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 4096,
                "stopSequences": [],
                "temperature": 0,
                "topP": 1
            }
        }

        body = json.dumps(payload)
        model_id = "amazon.titan-text-express-v1"
        response = bedrock.invoke_model(
            body=body,
            modelId = model_id,
            accept="application/json",
            contentType="application/json",
        )
        response_body = json.loads(response.get("body").read())
        response_text = (response_body.get("results")[0]).get('outputText')
        return (response_text)
    
