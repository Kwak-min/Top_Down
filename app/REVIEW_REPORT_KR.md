# Topdown Guard

국립순천대학교 캡스톤디자인 과제용 고령자를 위한 피싱 안전 AI 서비스 시제품입니다. 팀명은 탑다운입니다.

## 실행
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
브라우저는 `http://localhost:8000`을 사용합니다. 오프라인 검증은 `/api/offline/self-test` 또는 `scripts/run_offline_test.sh`입니다.

## 앱 실행
Android 에뮬레이터는 `http://10.0.2.2:8000`을 사용합니다. 실제 휴대폰은 PC와 같은 Wi-Fi에 연결한 뒤 PC 내부 IP(`http://192.168.x.x:8000`)를 입력합니다. SMS 테스트: `adb emu sms send 01000000000 "엄마 나 폰 고장났어. 지금 문화상품권 30만원 보내줘. 통화는 안돼."`

## 보안과 한계
API 키는 하드코딩하지 않고 `.env.example`만 제공합니다. SSRF 방어로 localhost, 127.0.0.1, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.169.254를 차단합니다. 정확도 목표 70%, UI/UX 개선 3회, 회의 10회, GitHub 업로드 10회는 문서상 관리 항목입니다.

## 15개 검토 항목
1. Python 문법 컴파일
2. 백엔드 단위/API 테스트
3. API 스모크 테스트
4. 보안 검토
5. 패키지 구성 검토
6. 모바일/AWS 정적 통합 검토
7. WAS 자체 기능 검토
8. Uvicorn WAS 런타임 검토
9. AWS CDK 정적 검토
10. 중간 단계 런타임 로그 검토
11. /api/logs/latest 검토
12. AWS/API 없는 오프라인 자체 검토
13. AWS/API 없는 오프라인 런타임 검토
14. 모바일 앱 정적 연결 검토
15. Shell/PowerShell 실행 스크립트 검토
