import boto3
import datetime
import json
import os

client = boto3.client('cloudwatch', region_name='us-east-1')


def get_estimated_billing(start=None, end=None):
    response = client.get_metric_statistics(
        Namespace='AWS/Billing',
        MetricName='EstimatedCharges',
        Dimensions=[
            {
                'Name': 'Currency',
                'Value': 'USD'
            },
        ],
        StartTime=start,
        EndTime=end,
        Period=86400,
        Statistics=[
            'Maximum',
        ],
        Unit='None'
    )
    return response['Datapoints'][0]['Maximum']


def calculate_final_billing(estimated_first_day, estimated_now, now):
    return ((estimated_now - estimated_first_day) / ( now.day - 1 ) + estimated_first_day)


def generate_message(final_billing):
    account_id = boto3.client('sts').get_caller_identity().get('Account')
    message = {
        "message": "Estimated billing is above threshold.",
        "threshold": os.environ['THRESHOLD'],
        "estimated_billing": final_billing,
        "account_id": account_id
    }
    return message


def lambda_handler(event, context):
    now = datetime.datetime.now()
    now_minus_day = now - datetime.timedelta(days=1)
    if now.day == 1:
        print("First day of the month. Estimation ")
        return

    estimated_now = get_estimated_billing(start=now_minus_day, end=now)
    print("Estimated billing now: {} USD".format(estimated_now))

    first_day_of_month_end = datetime.datetime.today().replace(day=1, hour=23)
    first_day_of_month_start = first_day_of_month_end - datetime.timedelta(hours=22)

    estimated_first_day = get_estimated_billing(start=first_day_of_month_start, end=first_day_of_month_end)
    print("Estimated billing at begginng of the month: {} USD".format(estimated_first_day))

    final_billing = calculate_final_billing(estimated_first_day, estimated_now, now)
    print("Estimated billing at end of the month: {} USD".format(final_billing))

    if final_billing > float(os.environ['THRESHOLD']):
        print("Sending meessage")
        message = generate_message(final_billing)
        client = boto3.client('sns')
        response = client.publish(
            TargetArn=os.environ['Topic_ARN'],
            Message=json.dumps(message)
        )

lambda_handler("event", "context")