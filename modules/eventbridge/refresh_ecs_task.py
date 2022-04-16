import boto3
import os


client = boto3.client('ecs')
cluster_nm = os.environ["CLUSTER_NM"]
service_nm = os.environ["SERVIVE_NM"]


def lambda_handler(event, context):
    response = client.update_service(
        cluster=cluster_nm, 
        service=service_nm, 
        forceNewDeployment=True)

    msg = (f'ECS service "{service_nm}" pulled new image & restarted')
    print(msg)
    return msg