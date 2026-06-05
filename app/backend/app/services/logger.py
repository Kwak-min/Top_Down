# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
import json
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
LOG_PATH = ROOT / "logs" / "pipeline_steps.jsonl"
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
def log_step(stage, details):
    entry = {"ts": datetime.now(timezone.utc).isoformat(), "stage": stage, "details": details}
    with LOG_PATH.open("a", encoding="utf-8") as f: f.write(json.dumps(entry, ensure_ascii=False)+"\n")
    return entry
def latest(limit=8):
    if not LOG_PATH.exists(): return []
    return [json.loads(x) for x in LOG_PATH.read_text(encoding="utf-8").splitlines()[-max(1,min(limit,100)):] if x.strip()]
