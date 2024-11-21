import boto3
import json
import logging
import os

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    # Initialize AWS clients
    wa_client = boto3.client('wellarchitected')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])  

    # Extract workload ID from the event
    workload_id = event['detail']['requestParameters']['WorkloadId']
    logger.info(f"Extracted WorkloadId: {workload_id}")
    
    # Extract MilestoneNumber from the event
    milestone_number = event['detail']['responseElements']['MilestoneNumber']
    logger.info(f"Extracted MilestoneNumber: {milestone_number}")


    try:
        workload = wa_client.get_workload(WorkloadId=workload_id)
        lenses = workload['Workload']['Lenses']
        logger.info(f"Lenses for workload {workload_id}: {lenses}")

        for lens_alias in lenses:
            next_token = None
            while True:
                if next_token:
                    # Include the NextToken in the request if it's present
                    response = wa_client.list_answers(WorkloadId=workload_id, LensAlias=lens_alias, NextToken=next_token)
                else:
                    response = wa_client.list_answers(WorkloadId=workload_id, LensAlias=lens_alias)

                for answer in response['AnswerSummaries']:
                    question_id = answer['QuestionId']
                    selected_choices = answer.get('SelectedChoices', [])
                    notes = answer.get('Notes', '')
                    risk = answer.get('Risk', '')

                    # Filter for high and medium risk questions
                    if risk in ['HIGH', 'MEDIUM']:
                        table.put_item(
                            Item={
                                'WorkloadId': workload_id,
                                'QuestionId': question_id,
                                'Risk': risk,
                                'SelectedChoices': json.dumps(selected_choices),
                                'Notes': notes
                            }
                        )
                        logger.info(f"Processed {risk} risk answer for question {question_id} for lens {lens_alias} in workload {workload_id}")

                next_token = response.get('NextToken')
                if not next_token:
                    break

    except Exception as e:
        logger.error(f"Error processing workload {workload_id}: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Error processing workload {workload_id}: {str(e)}"})
        }

    # Return workload_id and milestone_number in a structured JSON format
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f"Successfully processed high and medium risk questions for workload {workload_id}.",
            'workload_id': workload_id,
            'milestone_number': milestone_number  # Include MilestoneNumber in the output
        })
    }