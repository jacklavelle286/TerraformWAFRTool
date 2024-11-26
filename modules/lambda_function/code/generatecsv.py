import boto3
import csv
import io
import os
import json
import logging
import ast

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
    wa_client = boto3.client('wellarchitected')
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
    # Updated header to include ChoiceIds and ChoiceTitles
    csv_writer.writerow(['WorkloadId', 'QuestionId', 'Risk', 'SelectedChoices', 'Notes', 'ChoiceIds', 'ChoiceTitles'])

    for item in response['Items']:
        # Fetch the choices for each question
        try:
            question_details = wa_client.get_answer(
                WorkloadId=workload_id,
                LensAlias='wellarchitected',
                QuestionId=item['QuestionId'],
                MilestoneNumber=milestone_number,
            )
            choices = question_details['Answer'].get('Choices', [])
            # Extract ChoiceIds and ChoiceTitles
            choice_ids = [choice['ChoiceId'] for choice in choices]
            choice_titles = [choice['Title'] for choice in choices]
        except Exception as e:
            logger.error(f"Error fetching choices for QuestionId {item['QuestionId']}: {str(e)}")
            choice_ids = []
            choice_titles = []
        
        # Convert SelectedChoices to a list if it's a string
        selected_choices = item.get('SelectedChoices', '[]')
        if isinstance(selected_choices, str):
            try:
                selected_choices = ast.literal_eval(selected_choices)
            except Exception as e:
                logger.error(f"Error parsing SelectedChoices for QuestionId {item['QuestionId']}: {str(e)}")
                selected_choices = []

        # Write to CSV
        csv_writer.writerow([
            item['WorkloadId'],
            item['QuestionId'],
            item['Risk'],
            json.dumps(selected_choices),  # Ensure it's a JSON string
            item.get('Notes', ''),
            json.dumps(choice_ids),        # Store as JSON string
            json.dumps(choice_titles)      # Store as JSON string
        ])
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
