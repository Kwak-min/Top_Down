# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from .context_ai import analyze_context
from .logger import log_step
from .reported_numbers import lookup_sender
from .url_sandbox import check_url, extract_urls

def overlay_policy(verdict):
    if verdict=='block': return {'touch_block_required': True, 'message':'위험한 문자입니다. 누르지 마세요.'}
    if verdict=='warn': return {'touch_block_required': False, 'message':'의심 문자입니다. 가족이나 보호자에게 확인하세요.'}
    return {'touch_block_required': False, 'message':'현재 검사에서는 위험 신호가 낮습니다.'}
def analyze(sender,message,user_profile='senior',offline=True):
    plog=[]
    def step(stage,details):
        e=log_step(stage,details); plog.append(e); return e
    step('request_received',{'sender':sender,'user_profile':user_profile,'message_length':len(message)})
    urls=extract_urls(message); step('url_extraction',{'count':len(urls),'urls':urls})
    reported=lookup_sender(sender); step('reported_sender_lookup',reported)
    ctx=analyze_context(message,user_profile); step('context_ai_analysis',ctx)
    checks=[]
    for u in urls:
        c=check_url(u,offline); checks.append(c); step(c['mode'],c)
    reasons=[]
    if reported.get('reported'): reasons.append('신고된 발신 번호')
    reasons += ctx.get('reasons',[])
    for c in checks: reasons += [f"URL ??: {r}" for r in c.get('reasons',[])]
    url_score=max([c['risk_score'] for c in checks], default=0.0); sender_score=.35 if reported.get('reported') else 0.0
    risk=min(1.0, sender_score + ctx['risk_score']*.55 + url_score*.55)
    verdict='block' if risk>=.62 or any(c['verdict']=='block' for c in checks) else ('warn' if risk>=.32 else 'allow')
    step('risk_score_merge',{'sender_score':sender_score,'context_score':ctx['risk_score'],'url_score':url_score,'risk_score':round(risk,3),'verdict':verdict})
    overlay=overlay_policy(verdict); step('overlay_touch_block_policy',overlay)
    resp={'verdict':verdict,'risk_score':round(risk,3),'reasons':reasons or ['중대한 위험 신호 없음'],'reported_sender':reported,'context_ai':ctx,'url_checks':checks,'overlay':overlay,'pipeline_log':plog}
    step('response_ready',{'verdict':verdict,'risk_score':resp['risk_score']}); resp['pipeline_log']=plog; return resp
def self_test(offline=True):
    checks=[]
    def add(n,ok,d=None): checks.append({'name':n,'passed':bool(ok),'detail':d})
    r=analyze('01000000000','\uc5c4\ub9c8 \ub098 \ud3f0 \uace0\uc7a5\ub0ac\uc5b4. \uc9c0\uae08 \uc0c1\ud488\uad8c 30\ub9cc\uc6d0 \ubcf4\ub0b4\uc918. \ud1b5\ud654\ub294 \uc548\ub3fc. http://phish.test','senior',offline)
    add('reported_sender_lookup',r['reported_sender'].get('reported') is True,r['reported_sender'])
    add('context_ai_analysis',r['context_ai']['risk_score']>.3,r['context_ai'])
    add('url_sandbox',any(c['verdict'] in {'warn','block'} for c in r['url_checks']),r['url_checks'])
    add('overlay_policy',r['overlay']['touch_block_required'] is True,r['overlay'])
    add('pipeline_log',len(r['pipeline_log'])>=8,len(r['pipeline_log']))
    add('safe_message_allow',analyze('01022223333','\uc624\ub298 \uc800\ub141 \uc2dd\uc0ac \uac19\uc774 \ud574\uc694','senior',offline)['verdict']=='allow')
    add('ssrf_block',check_url('http://169.254.169.254/latest/meta-data',True)['verdict']=='block')
    passed=sum(1 for c in checks if c['passed'])
    return {'status':'PASS' if passed==len(checks) else 'FAIL','mode':'no_aws_no_external_api_no_dns_no_http' if offline else 'was_local','passed':passed,'failed':len(checks)-passed,'checks':checks}
