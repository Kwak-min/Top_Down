# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
import json
from pathlib import Path
DATA = Path(__file__).resolve().parents[1] / "data" / "police_reported_numbers.json"
def normalize(n): return "".join(ch for ch in n if ch.isdigit())
def lookup_sender(sender):
    data=json.loads(DATA.read_text(encoding="utf-8")); key=normalize(sender); rec=data.get(key)
    return ({"reported": True, "source":"local_fixture", "sender":key, **rec} if rec else {"reported":False,"source":"local_fixture","sender":key})
