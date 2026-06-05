# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]/'logs/pipeline_steps.jsonl'; lines=p.read_text(encoding='utf-8').splitlines() if p.exists() else []
stages={json.loads(x)['stage'] for x in lines if x.strip()}; need={'request_received','url_extraction','reported_sender_lookup','context_ai_analysis','offline_url_sandbox','risk_score_merge','overlay_touch_block_policy','response_ready'}; miss=sorted(need-stages)
print({'status':'PASS' if not miss else 'FAIL','lines':len(lines),'missing':miss}); raise SystemExit(0 if not miss else 1)
