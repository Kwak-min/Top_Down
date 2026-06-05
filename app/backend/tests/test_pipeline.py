# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
from fastapi.testclient import TestClient
from app.main import app
from app.services.reported_numbers import lookup_sender
from app.services.context_ai import analyze_context
from app.services.url_sandbox import extract_urls, check_url
client=TestClient(app)
def test_reported_number_lookup(): assert lookup_sender('010-0000-0000')['reported'] is True
def test_context_ai(): assert analyze_context('\uc5c4\ub9c8 \ub098 \ud3f0 \uace0\uc7a5\ub0ac\uc5b4 \uc0c1\ud488\uad8c \ubcf4\ub0b4\uc918 \ud1b5\ud654\ub294 \uc548\ub3fc')['risk_score']>.3
def test_obfuscated_money_context():
    r=analyze_context('오늘만 1ㅇ0ㅇ0원 보내면 지원금 신청 가능')
    assert r['risk_score']>.25
    assert any(m['rule']=='obfuscated_money_amount' for m in r['matches'])
def test_url_extract(): assert extract_urls('?? http://phish.test/a')==['http://phish.test/a']
def test_offline_url_check(): assert check_url('http://phish.test')['verdict'] in {'warn','block'}
def test_ssrf_block(): assert check_url('http://127.0.0.1/admin')['verdict']=='block'
def test_api_analyze(): assert client.post('/api/analyze',json={'sender':'01000000000','message':'\uc5c4\ub9c8 \ub098 \ud3f0 \uace0\uc7a5\ub0ac\uc5b4 \uc0c1\ud488\uad8c \ubcf4\ub0b4\uc918 \ud1b5\ud654\ub294 \uc548\ub3fc','user_profile':'senior'}).json()['verdict']=='block'
def test_offline_self_test(): assert client.get('/api/offline/self-test').json()['status']=='PASS'
def test_was_self_test(): assert client.get('/api/was/self-test').json()['status']=='PASS'
def test_pipeline_log_created(): assert len(client.post('/api/analyze',json={'sender':'01000000000','message':'http://phish.test \uc5c4\ub9c8 \uc0c1\ud488\uad8c','user_profile':'senior'}).json()['pipeline_log'])>=8
def test_logs_latest(): client.get('/api/offline/self-test'); assert 'items' in client.get('/api/logs/latest?limit=8').json()
def test_normal_false_positive(): assert client.post('/api/analyze',json={'sender':'01022223333','message':'\uc624\ub298 \uc800\ub141 \uc2dd\uc0ac \uac19\uc774 \ud574\uc694','user_profile':'senior'}).json()['verdict']=='allow'
def test_risky_message_block(): assert client.post('/api/analyze',json={'sender':'01000000000','message':'\uc5c4\ub9c8 \ud3f0 \uace0\uc7a5 \uc0c1\ud488\uad8c \uc9c0\uae08 \ud1b5\ud654\ub294 \uc548\ub3fc','user_profile':'senior'}).json()['verdict']=='block'
def test_obfuscated_money_warn_or_block(): assert client.post('/api/analyze',json={'sender':'01022223333','message':'오늘만 1ㅇ0ㅇ0원 보내면 지원금 신청 가능','user_profile':'senior'}).json()['verdict'] in {'warn','block'}
def test_overlay_true(): assert client.post('/api/analyze',json={'sender':'01000000000','message':'\uc5c4\ub9c8 \ud3f0 \uace0\uc7a5 \uc0c1\ud488\uad8c \uc9c0\uae08 \ud1b5\ud654\ub294 \uc548\ub3fc','user_profile':'senior'}).json()['overlay']['touch_block_required'] is True
