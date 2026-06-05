# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from fastapi.testclient import TestClient
from pathlib import Path
import sys
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
from app.main import app
c=TestClient(app); r=c.get('/api/offline/self-test').json(); print(r); raise SystemExit(0 if r['status']=='PASS' else 1)
