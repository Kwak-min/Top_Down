# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
import math, re
from collections import Counter
PHISHING_SAMPLES=["\uc5c4\ub9c8 \ub098 \ud3f0 \uace0\uc7a5\ub0ac\uc5b4 \uc0c1\ud488\uad8c \ubcf4\ub0b4\uc918 \ud1b5\ud654\ub294 \uc548\ub3fc \uae34\uae09", "\uc9c0\uc6d0\uae08 \uc2e0\uccad \uc624\ub298\uae4c\uc9c0 \ubcf8\uc778 \ud655\uc778 \uacc4\uc88c \uc778\uc99d \ub9c1\ud06c", "\uce74\ub4dc \ube44\ubc00\ubc88\ud638 \uc778\uc99d\ubc88\ud638 \uc785\ub825 \uc6d0\uaca9 \uc571 \uc124\uce58", "\ud0dd\ubc30 \uc8fc\uc18c \uc624\ub958 \ud655\uc778 \ub9c1\ud06c", "\ub300\ucd9c \uc2b9\uc778 \uc218\uc218\ub8cc \uc785\uae08 \uacc4\uc88c \uc778\uc99d"]
NORMAL_SAMPLES=["\uc624\ub298 \uc800\ub141 \uac19\uc774 \uc2dd\uc0ac\ud574\uc694", "\ubcd1\uc6d0 \uc608\uc57d \ud655\uc778 \ubb38\uc790\uc785\ub2c8\ub2e4", "\ud68c\uc758 \uc2dc\uac04\uc774 \uc624\ud6c4 \uc138\uc2dc\ub85c \ubcc0\uacbd", "\uc8fc\ubb38\ud558\uc2e0 \uc0c1\ud488\uc774 \ubc30\uc1a1 \uc644\ub8cc", "\uac00\uc871 \ubaa8\uc784 \uc7a5\uc18c"]
RISK_RULES={"family_impersonation":["\uc5c4\ub9c8","\uc544\ube60","\ud3f0 \uace0\uc7a5","\ud734\ub300\ud3f0 \uace0\uc7a5","\ud1b5\ud654\ub294 \uc548\ub3fc"],"money_request":["\uc0c1\ud488\uad8c","\ubb38\ud654\uc0c1\ud488\uad8c","\uacc4\uc88c","\uc785\uae08","\uc1a1\uae08","\uc218\uc218\ub8cc","\uc6d0"],"urgency":["\uae34\uae09","\uc624\ub298\uae4c\uc9c0","\uc624\ub298\ub9cc","\uc9c0\uae08","\uc989\uc2dc","\ub9c8\uac10"],"identity":["\ubcf8\uc778 \ud655\uc778","\uacc4\uc88c \uc778\uc99d","\uc778\uc99d\ubc88\ud638","\ube44\ubc00\ubc88\ud638","\uce74\ub4dc"],"remote_app":["\uc6d0\uaca9 \uc571","\uc6d0\uaca9\uc81c\uc5b4","\uc124\uce58","apk"],"public_support":["\uc9c0\uc6d0\uae08","\ud658\uae09","\ubcf4\uc870\uae08","\uc2e0\uccad"]}
CONFUSABLES=str.maketrans({'ㅇ':'0','О':'0','о':'0','O':'0','o':'0','I':'1','l':'1','|':'1','₩':'원'})
TOKEN_RE=re.compile(r"[\uac00-\ud7a3A-Za-z0-9]+")
MONEY_RE=re.compile(r"\d+[\d,]*(?:원|만원|천원)")
def normalize_message(t):
    s=(t or '').lower().translate(CONFUSABLES)
    s=re.sub(r"\s+", " ", s)
    s=re.sub(r"(?<=\d)[\s,._-]+(?=\d)", "", s)
    return s
def compact_message(t): return re.sub(r"[^\uac00-\ud7a3a-z0-9]+", "", normalize_message(t))
def tokens(t): return TOKEN_RE.findall(normalize_message(t))
def counts(samples):
    c=Counter(); total=0
    for s in samples:
        ts=tokens(s); c.update(ts); total+=len(ts)
    return c,total
P,PT=counts(PHISHING_SAMPLES); N,NT=counts(NORMAL_SAMPLES); VOC=set(P)|set(N)
def nb_score(msg):
    ts=tokens(msg); lp=math.log(.55); ln=math.log(.45); v=len(VOC)+1
    for t in ts: lp+=math.log((P[t]+1)/(PT+v)); ln+=math.log((N[t]+1)/(NT+v))
    m=max(lp,ln); ep,en=math.exp(lp-m),math.exp(ln-m); return ep/(ep+en) if ts else 0.0
def analyze_context(message,user_profile='senior'):
    normalized=normalize_message(message); compact=compact_message(message); matched=[]; rule=0.0
    for name,kws in RISK_RULES.items():
        hits=[kw for kw in kws if kw.lower() in normalized or kw.replace(' ','').lower() in compact]
        if hits: matched.append({'rule':name,'hits':hits}); rule+=min(.18,.07*len(hits))
    money_hits=MONEY_RE.findall(normalized)
    if money_hits:
        matched.append({'rule':'obfuscated_money_amount','hits':money_hits}); rule+=.24
    if any(x in compact for x in ['오늘만','오늘까지','지금']) and money_hits:
        matched.append({'rule':'urgent_money_request','hits':['긴급 금전 요구']}); rule+=.32
    if user_profile=='senior' and matched: rule+=.08
    ml=nb_score(normalized); score=min(1.0, rule*.62+ml*.38)
    reasons=[f"\ubb38\ub9e5 \ud0d0\uc9c0: {m['rule']}({', '.join(m['hits'])})" for m in matched]
    if ml>=.65: reasons.append("\uc0d8\ud50c \uae30\ubc18 Naive Bayes \ubb38\ub9e5 \ubd84\uc11d\uc5d0\uc11c \ud53c\uc2f1 \uac00\ub2a5\uc131\uc774 \ub192\uc74c")
    return {'risk_score':round(score,3),'rule_score':round(min(1,rule),3),'naive_bayes_score':round(ml,3),'matches':matched,'reasons':reasons}
