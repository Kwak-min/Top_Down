# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pathlib import Path
text=(Path(__file__).resolve().parents[1]/'infra/aws_cdk/app.py').read_text(encoding='utf-8')
need=['ApplicationLoadBalancedFargateService','ApiBaseUrl','WasSelfTestUrl']; miss=[x for x in need if x not in text]
print({'status':'PASS' if not miss else 'FAIL','missing':miss}); raise SystemExit(0 if not miss else 1)
