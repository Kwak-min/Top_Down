# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from pathlib import Path
root=Path(__file__).resolve().parents[1]; text=(root/'mobile_flutter/android/app/src/main/AndroidManifest.xml').read_text(encoding='utf-8')+(root/'mobile_flutter/android/app/src/main/kotlin/com/topdown/guard/SmsReceiver.kt').read_text(encoding='utf-8')+(root/'mobile_flutter/android/app/src/main/kotlin/com/topdown/guard/OverlayBlockService.kt').read_text(encoding='utf-8')
need=['RECEIVE_SMS','SYSTEM_ALERT_WINDOW','SmsReceiver','OverlayBlockService','/api/analyze']
miss=[x for x in need if x not in text]
print({'status':'PASS' if not miss else 'FAIL','missing':miss}); raise SystemExit(0 if not miss else 1)
