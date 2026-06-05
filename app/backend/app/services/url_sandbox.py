# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
import ipaddress, re
from urllib.parse import urlparse
URL_RE = re.compile("https?://[^\\s\"\'<>]+", re.I)
SHORTENERS={"bit.ly","tinyurl.com","t.co","goo.gl","is.gd","cutt.ly","url.kr"}
SUSPICIOUS=["secure-bank","kakao-pay-check","gift-card","account-verify","support-money","login-auth"]
PRIVATE_NETS=[ipaddress.ip_network(x) for x in ["127.0.0.0/8","0.0.0.0/8","10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","169.254.0.0/16","::1/128","fc00::/7","fe80::/10"]]
FIXTURES={"phish.test": '<form><input name="account"><input name="password"><a href="malware.apk">APK 설치</a></form>원격제어 앱 설치 인증번호',"safe.test":"<h1>지역 복지 안내</h1>","bank-login.test":'<form><input name="card"><input name="pin"><input name="otp"></form>'}
def extract_urls(text): return [u.rstrip(".,)];") for u in URL_RE.findall(text or "")]
def is_internal_host(host):
    if not host: return True
    h=host.strip('[]').lower()
    if h in {'localhost','metadata.google.internal'}: return True
    try:
        ip=ipaddress.ip_address(h); return any(ip in n for n in PRIVATE_NETS) or h=='169.254.169.254'
    except ValueError: return False
def check_url(url, offline=True):
    p=urlparse(url); host=(p.hostname or '').lower(); reasons=[]
    if p.scheme!='https': reasons.append('http 사용 또는 안전하지 않은 스킴')
    if is_internal_host(host): reasons.append('내부망/localhost/메타데이터 주소 접근 차단')
    if host in SHORTENERS: reasons.append('단축 URL 사용')
    if any(x in host for x in SUSPICIOUS): reasons.append('수상한 도메인 패턴')
    html=FIXTURES.get(host,''); low=html.lower()
    if '<form' in low and any(x in low for x in ['password','account','card','otp','pin','인증번호']): reasons.append('민감정보 입력 폼 탐지')
    if '.apk' in low or 'apk' in low: reasons.append('APK 다운로드 유도')
    if '원격' in html or 'remote' in low: reasons.append('원격제어 앱 설치 유도')
    score=min(1.0,.22*len(reasons)); verdict='block' if any('내부망' in r for r in reasons) or score>=.58 else ('warn' if reasons else 'allow')
    return {'url':url,'mode':'offline_url_sandbox' if offline else 'aws_was_url_sandbox','verdict':verdict,'risk_score':round(score,3),'reasons':reasons,'host':host}
