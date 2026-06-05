# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pathlib import Path
root=Path(__file__).resolve().parents[1]
text='\n'.join(p.read_text(encoding='utf-8',errors='ignore') for p in root.rglob('*') if p.is_file() and p.suffix in {'.py','.kt','.dart','.md','.yml','.yaml','.json','.txt','.sh','.ps1','.example'})
need=['169.254.169.254','127.0.0.0/8','SYSTEM_ALERT_WINDOW','.env.example']
miss=[x for x in need if x not in text]
print({'status':'PASS' if not miss else 'FAIL','missing':miss}); raise SystemExit(0 if not miss else 1)
