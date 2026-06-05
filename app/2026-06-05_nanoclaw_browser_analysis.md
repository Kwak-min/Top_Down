# 2026-06-05 NanoClaw 브라우저 기반 피싱 분석 작동 방식

## 목적

Topdown Guard는 사용자가 입력한 URL을 Jetson의 NanoClaw 분석 API로 전달하고, NanoClaw가 해당 사이트를 실제 브라우저 환경에서 열어 본 뒤 피싱 여부를 판단하는 구조를 목표로 한다.

기존 문자 기반 검사는 제거하고, 현재 방향은 다음과 같다.

```text
사용자 URL 입력
→ Topdown Guard 프론트엔드
→ Topdown Guard backend proxy
→ Tailscale을 통한 Jetson NanoClaw API
→ NanoClaw 브라우저 분석
→ verdict / evidence_summary 반환
→ 프론트엔드 표시
```

## 현재 연결 방식

Jetson NanoClaw API는 Tailscale 주소를 사용한다.

```text
NanoClaw API Base: http://100.109.47.20:8000
Health: GET http://100.109.47.20:8000/health
Analyze: POST http://100.109.47.20:8000/analyze
```

Topdown Guard backend는 브라우저가 Jetson API를 직접 호출하지 않도록 프록시 역할을 한다.

```text
Frontend request:
POST /api/nanoclaw/analyze

Backend proxy target:
POST http://100.109.47.20:8000/analyze
```

이 구조를 사용하는 이유는 브라우저의 CORS 문제와 네트워크 접근 문제를 피하기 위해서다.

## 현재 테스트 결과

2026-06-05 기준 테스트 결과:

### Jetson health

```text
GET http://100.109.47.20:8000/health
```

응답:

```json
{
  "status": "ok",
  "host": "192.168.10.99",
  "nanoclaw_socket": "/home/user/nanoclaw/data/cli.sock",
  "nanoclaw_socket_exists": true
}
```

### Analyze 테스트

요청:

```http
POST /api/nanoclaw/analyze
Content-Type: application/json

{
  "url": "https://example.com"
}
```

응답 요약:

```json
{
  "url": "https://example.com",
  "verdict": "legitimate",
  "is_phishing": false,
  "confidence": 1.0,
  "evidence_summary": {
    "fetch_status": "200",
    "final_url": "https://example.com",
    "title": "Example Domain"
  }
}
```

브라우저 UI에서도 `NanoClaw API 검사` 버튼 클릭 시 다음 요청이 정상 수행되었다.

```text
POST http://127.0.0.1:<local-port>/api/nanoclaw/analyze => 200 OK
```

## NanoClaw 판단 방식 목표

NanoClaw는 단순히 URL 문자열만 보고 판단하지 않는다. 목표 판단 방식은 NanoClaw가 직접 브라우저를 열고 사이트에 접근한 뒤, 페이지 내부 동작을 관찰하고 그 결과를 근거로 피싱 여부를 판단하는 것이다.

```text
NanoClaw receives URL
→ creates isolated browser session
→ opens target URL
→ observes page content
→ clicks limited suspicious candidates
→ watches downloads/network/posts/popups
→ collects evidence
→ makes final phishing judgment
```

## 브라우저 분석 세션 방식

요청마다 독립된 임시 분석 세션을 만든다.

- `tempfile.TemporaryDirectory` 사용
- Playwright Chromium 사용
- 요청마다 새 browser context 생성
- 다운로드 디렉터리 분리
- 분석 완료 후 context/page/browser 종료
- 임시 파일 정리
- 실패해도 `finally`에서 정리

## NanoClaw가 수집해야 하는 증거

NanoClaw는 다음 정보를 수집한 뒤 판단해야 한다.

- 최초 요청 URL
- 최종 리다이렉트 URL
- HTTP status
- content type
- page title
- visible text sample
- full-page screenshot
- form 목록
- input 목록
- password / OTP / card / wallet / seed phrase / login / email / phone 힌트
- button 목록
- link 목록
- 외부 링크 host
- POST request host
- popup/new tab URL
- redirect chain
- download event
- download filename / extension / size / sha256 / MIME 추정값
- 클릭 전후 URL/title/text 변화
- 분석 중 error

## 클릭 분석 방식

NanoClaw는 모든 요소를 무작정 누르지 않고 위험 후보만 제한적으로 클릭한다.

클릭 후보 예시:

```text
로그인
인증
본인확인
계속
확인
다운로드
설치
열기
verify
login
sign in
continue
confirm
download
install
open
```

제한 조건:

- 최대 클릭 수: 5개
- form submit 금지
- 실제 계정/비밀번호/카드/OTP/시드구문 입력 금지
- 민감 입력칸이 있으면 존재만 기록
- 새 탭/팝업은 URL 기록 후 닫기
- 클릭 후 다운로드 이벤트 기록
- 클릭 후 POST 요청 기록
- 클릭 후 리다이렉트 기록

## 다운로드 판단 방식

다운로드 파일은 절대 실행하지 않는다.

다운로드가 발생하면 다음만 기록한다.

- suggested filename
- 저장 path
- 확장자
- 파일 크기
- sha256
- MIME 추정값

위험 확장자 예시:

```text
.apk
.exe
.msi
.bat
.cmd
.scr
.ps1
.zip
.rar
.7z
```

다운로드 파일은 분석 후 삭제한다.

## 안전 정책

NanoClaw 브라우저 분석은 다음 정책을 지켜야 한다.

- 다운로드 파일 실행 금지
- 실제 민감정보 입력 금지
- form submit 금지
- 내부망/메타데이터 주소 접근 차단
- 최대 분석 시간 제한
- 최대 클릭 수 제한
- 최대 다운로드 수 제한
- 요청마다 브라우저 세션 격리
- 분석 후 임시 파일 정리

차단 대상 예시:

```text
localhost
127.0.0.1
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.169.254
metadata.google.internal
```

## 최종 응답 구조

기존 API 응답 구조는 유지한다.

```json
{
  "url": "https://example.com",
  "verdict": "phishing | suspicious | legitimate | unknown",
  "is_phishing": false,
  "confidence": 1.0,
  "reasoning": "한국어 판단 설명",
  "nanoclaw_response": "Raw NanoClaw judgment text",
  "evidence_summary": {}
}
```

## evidence_summary 목표 구조

```json
{
  "fetch_status": "200",
  "final_url": "https://example.com",
  "title": "Example Domain",
  "forms": [],
  "inputs": [],
  "sensitive_field_hints": [],
  "button_count": 0,
  "link_count": 1,
  "external_link_hosts": ["iana.org"],
  "download_candidates": [],
  "screenshot": {
    "status": "captured",
    "screenshot_path": "/tmp/nanoclaw-shot-xxxx.png",
    "page_title": "Example Domain",
    "visible_text_sample": "...",
    "clicked_candidates": [],
    "click_results": [],
    "popup_urls": [],
    "download_events": [],
    "network_post_hosts": [],
    "redirect_chain": [],
    "errors": []
  },
  "sandbox": {
    "mode": "nanoclaw_browser_sandbox",
    "isolated_context": true,
    "temp_dir_used": true,
    "cleanup_status": "done",
    "max_clicks": 5,
    "max_runtime_seconds": 120
  }
}
```

## Verdict 기준

```text
phishing:
- credential 입력칸 + 브랜드 사칭 + 로그인/인증 유도
- OTP/card/password/seed phrase 요구
- APK/EXE/MSI 등 실행 파일 다운로드 유도
- 단축 URL/리다이렉트/위장 도메인 + 민감 입력 요구

suspicious:
- 증거가 충분하지 않지만 이상 동작 있음
- 과도한 리다이렉트
- 외부 POST host 발생
- 다운로드 후보 존재

legitimate:
- 명확한 정상 사이트
- 민감 입력/다운로드/위장/위험 네트워크 동작 없음

unknown:
- 접근 실패
- 분석 실패
- 증거 부족
```

## 프론트엔드 표시 방식

현재 프론트엔드는 문자 검사를 제거하고 NanoClaw URL 분석만 표시한다.

사용자 동작:

```text
URL 입력
→ 페이지 열기 또는 NanoClaw API 검사 클릭
→ /api/nanoclaw/analyze 요청
→ verdict/confidence/reasoning/evidence_summary 표시
```

브라우저 안 iframe은 사용자가 참고용으로 페이지를 열어보는 영역이며, 최종 판단은 Jetson NanoClaw API가 수행한다.

## 유지해야 할 점

- NanoClaw 이름 유지
- NanoClaw/OpenRouter 판단 로직 유지
- `/health`, `/analyze` API 계약 유지
- Tailscale 연결 유지
- 다운로드 실행 금지
- 민감정보 입력 금지
- form submit 금지
- 요청별 임시 브라우저 세션 정리
