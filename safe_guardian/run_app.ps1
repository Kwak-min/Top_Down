# 안심지킴이 앱 빌드 & 실행 스크립트
Write-Host "=== 안심지킴이 빌드 시작 ===" -ForegroundColor Cyan

# 1. 최신 소스 복사
Write-Host "[1/4] 소스 복사 중..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "C:\flutter_projects\safe_guardian" -ErrorAction SilentlyContinue
Copy-Item -Recurse "c:\Users\A\Documents\Github Clone 파일\Top_Down\safe_guardian" "C:\flutter_projects\safe_guardian"
Write-Host "     완료!" -ForegroundColor Green

# 2. 프로젝트 디렉토리로 이동
Set-Location "C:\flutter_projects\safe_guardian"

# 3. 패키지 설치
Write-Host "[2/4] 패키지 설치 중..." -ForegroundColor Yellow
C:\flutter\bin\flutter.bat pub get
Write-Host "     완료!" -ForegroundColor Green

# 4. 에뮬레이터 확인
Write-Host "[3/4] 기기 확인..." -ForegroundColor Yellow
C:\flutter\bin\flutter.bat devices

# 5. 빌드 & 실행
Write-Host "[4/4] 앱 빌드 & 실행 중... (2~4분 소요)" -ForegroundColor Yellow
C:\flutter\bin\flutter.bat run -d emulator-5554
