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

## WAS_AWS_FUNCTION_REVIEW_KR.md
