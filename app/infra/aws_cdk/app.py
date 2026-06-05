# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
#!/usr/bin/env python3
from aws_cdk import App, Stack, CfnOutput
from aws_cdk import aws_ec2 as ec2, aws_ecs as ecs
from aws_cdk.aws_ecs_patterns import ApplicationLoadBalancedFargateService, ApplicationLoadBalancedTaskImageOptions
from constructs import Construct
class TopdownGuardStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)
        vpc=ec2.Vpc(self,'Vpc',max_azs=2); cluster=ecs.Cluster(self,'Cluster',vpc=vpc)
        svc=ApplicationLoadBalancedFargateService(self,'Was',cluster=cluster,cpu=512,memory_limit_mib=1024,desired_count=1,task_image_options=ApplicationLoadBalancedTaskImageOptions(image=ecs.ContainerImage.from_registry('public.ecr.aws/docker/library/python:3.11-slim'),container_port=8000))
        CfnOutput(self,'ApiBaseUrl',value='http://'+svc.load_balancer.load_balancer_dns_name)
        CfnOutput(self,'WasSelfTestUrl',value='http://'+svc.load_balancer.load_balancer_dns_name+'/api/was/self-test')
app=App(); TopdownGuardStack(app,'TopdownGuardStack'); app.synth()
