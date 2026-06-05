# pyright: reportOperatorIssue=false, reportAttributeAccessIssue=false, reportArgumentType=false, reportIndexIssue=false, reportCallIssue=false, reportGeneralTypeIssues=false, reportMissingImports=false
import json, os
from pathlib import Path
from fastapi import FastAPI, Query
import httpx
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from .models.schemas import AnalyzeRequest, AnalyzeResponse, NanoclawAnalyzeRequest, UrlCheckRequest
from .services.logger import latest
from .services.pipeline import analyze, self_test
from .services.url_sandbox import check_url
BASE=Path(__file__).resolve().parent
NANOCLAW_API_BASE=os.getenv('NANOCLAW_API_BASE','http://100.109.47.20:8000').rstrip('/')
app=FastAPI(title='Topdown Guard',version='1.0.0')
app.add_middleware(CORSMiddleware,allow_origins=['*'],allow_credentials=True,allow_methods=['*'],allow_headers=['*'])
app.mount('/static',StaticFiles(directory=str(BASE/'static')),name='static')
@app.get('/')
def index(): return FileResponse(BASE/'static'/'index.html')
@app.post('/api/analyze',response_model=AnalyzeResponse)
def api_analyze(req:AnalyzeRequest): return analyze(req.sender,req.message,req.user_profile,offline=True)
@app.post('/api/url/check')
def api_url_check(req:UrlCheckRequest): return check_url(req.url,offline=req.offline)
@app.get('/api/was/self-test')
def was_self_test(): return self_test(offline=True)
@app.get('/api/offline/self-test')
def offline_self_test(): return self_test(offline=True)
@app.post('/api/offline/analyze',response_model=AnalyzeResponse)
def offline_analyze(req:AnalyzeRequest): return analyze(req.sender,req.message,req.user_profile,offline=True)
@app.post('/api/offline/url/check')
def offline_url_check(req:UrlCheckRequest): return check_url(req.url,offline=True)
@app.get('/api/nanoclaw/health')
def nanoclaw_health():
    try:
        with httpx.Client(timeout=10.0) as client:
            r=client.get(f'{NANOCLAW_API_BASE}/health')
            r.raise_for_status()
            data=r.json()
        return {'status':'ok','api_base':NANOCLAW_API_BASE,'nanoclaw':data}
    except httpx.HTTPError as e:
        return {'status':'error','api_base':NANOCLAW_API_BASE,'message':str(e)}
@app.post('/api/nanoclaw/analyze')
def nanoclaw_analyze(req:NanoclawAnalyzeRequest):
    try:
        with httpx.Client(timeout=300.0) as client:
            r=client.post(f'{NANOCLAW_API_BASE}/analyze',json={'url':req.url})
            r.raise_for_status()
            return r.json()
    except httpx.HTTPStatusError as e:
        return {'url':req.url,'verdict':'unknown','is_phishing':False,'confidence':0.0,'reasoning':f'NanoClaw API 응답 오류: {e.response.status_code}','nanoclaw_response':e.response.text,'evidence_summary':{}}
    except httpx.HTTPError as e:
        return {'url':req.url,'verdict':'unknown','is_phishing':False,'confidence':0.0,'reasoning':f'NanoClaw API 통신 실패: {e}','nanoclaw_response':'','evidence_summary':{}}
@app.get('/api/offline/scenarios/{case_id}/analyze')
def scenario(case_id:str):
    data=json.loads((BASE/'data'/'scenarios.json').read_text(encoding='utf-8'))
    if case_id not in data: return {'status':'FAIL','reason':'unknown_case','available':sorted(data)}
    s=data[case_id]; return analyze(s['sender'],s['message'],s.get('user_profile','senior'),offline=True)
@app.get('/api/logs/latest')
def logs_latest(limit:int=Query(default=8,ge=1,le=100)): return {'items':latest(limit)}
