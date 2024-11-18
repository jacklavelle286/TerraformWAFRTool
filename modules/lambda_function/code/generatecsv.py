import boto3
import csv
import io
import os
import json
import logging

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    
    # Parse the event as JSON and extract the Workload ID
    event_data = json.loads(event['body'])
    workload_id = event_data['workload_id']
    logger.info(f"Extracted workload_id: {workload_id}")
    
    # Parse the milestone_number along with the workload_id
    milestone_number = event_data['milestone_number']
    logger.info(f"Extracted milestone_number: {milestone_number}")


    # Initialize AWS clients
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.client('s3')
    logger.info("Initialized AWS clients")

    # Reference the DynamoDB table
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    logger.info(f"Referenced DynamoDB table: {os.environ['DYNAMODB_TABLE']}")

    # Query the table for items related to the provided Workload ID
    try:
        response = table.query(
            KeyConditionExpression='WorkloadId = :workload_id',
            ExpressionAttributeValues={
                ':workload_id': workload_id
            }
        )
        logger.info(f"Queried DynamoDB table. Items count: {len(response['Items'])}")
    except Exception as e:
        logger.error(f"Error querying DynamoDB: {str(e)}")
        raise

    # Generate CSV content
    csv_content = io.StringIO()
    csv_writer = csv.writer(csv_content)
    csv_writer.writerow(['WorkloadId', 'QuestionId', 'Risk', 'SelectedChoices', 'Notes'])  # Header

    for item in response['Items']:
        csv_writer.writerow([item['WorkloadId'], item['QuestionId'], item['Risk'], item['SelectedChoices'], item['Notes']])
    logger.info("CSV content generated")

    # Upload CSV to S3 bucket
    try:
        s3.put_object(
            Bucket=os.environ['CSV_BUCKET'],
            Key=f'{workload_id}.csv',
            Body=csv_content.getvalue()
        )
        logger.info(f"CSV uploaded to S3 bucket: {os.environ['CSV_BUCKET']}, Key: {workload_id}.csv")
    except Exception as e:
        logger.error(f"Error uploading CSV to S3: {str(e)}")
        raise

    # Return the S3 path of the uploaded CSV and pass both workload_id and milestone_number to the next function
    result = {
        'statusCode': 200,
        'csv_s3_key': f'{workload_id}.csv',
        'workload_id': workload_id,
        'milestone_number': milestone_number  # Include milestone_number in the output
    }
    logger.info(f"Function output: {result}")
    return result