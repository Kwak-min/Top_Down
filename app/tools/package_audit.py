# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pathlib import Path
root=Path(__file__).resolve().parents[1]; req=['backend/requirements.txt','docker-compose.yml','backend/Dockerfile','mobile_flutter/pubspec.yaml']; miss=[x for x in req if not (root/x).exists()]
print({'status':'PASS' if not miss else 'FAIL','missing':miss}); raise SystemExit(0 if not miss else 1)
