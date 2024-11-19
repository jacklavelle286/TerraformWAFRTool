import boto3
import os
import json
import logging

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
logger.info(f"Received event: {event}")

# Parse the 'body' field from the event to get a dictionary
body = json.loads(event['body'])
logger.info(f"Parsed body: {body}")

bucket_name = body['s3Bucket']
object_key = body['reportFilename']
milestone_name = body['milestoneName']
logger.info(f"Extracted bucket name: {bucket_name}, object key: {object_key}, and milestone name: {milestone_name}")

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
sns_topic_arn = os.environ['SNS_TOPIC']
logger.info("Initialized S3 and SNS clients")

try:
    presigned_url = s3_client.generate_presigned_url('get_object',
                                                    Params={'Bucket': bucket_name, 'Key': object_key},
                                                    ExpiresIn=3600)
    logger.info(f"Generated presigned URL: {presigned_url}")
except Exception as e:
    logger.error(f"Error generating presigned URL: {str(e)}")
    raise

# Simple text message including the URL
message = f'{milestone_name} has completed a new Well-Architected Review, and their report is available to download here: {presigned_url}'

try:
    sns_response = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=message,
        Subject=f'{milestone_name}: Well-Architected Report Available'
    )
    logger.info(f"Published message to SNS topic. SNS Message ID: {sns_response['MessageId']}")
except Exception as e:
    logger.error(f"Error publishing to SNS topic: {str(e)}")
    raise

return {
    'statusCode': 200,
    'body': f"Presigned URL published to SNS topic. SNS Message ID: {sns_response['MessageId']}"
}
