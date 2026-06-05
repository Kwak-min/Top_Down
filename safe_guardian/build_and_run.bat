@echo off
echo === 안심지킴이 빌드 시작 ===

echo [1] C:\sg 정리 중...
if exist C:\sg rmdir /s /q C:\sg
mkdir C:\sg

echo [2] 소스 복사 중...
xcopy "c:\Users\A\Documents\Github Clone 파일\Top_Down\safe_guardian" C:\sg /E /I /Q

echo [3] pubspec.yaml 충돌 마커 제거 중...
(
echo name: safe_guardian
echo description: "안심지킴이 - 시니어 피싱 방어 앱"
echo publish_to: 'none'
echo version: 1.0.0+1
echo.
echo environment:
echo   sdk: ^3.11.4
echo.
echo dependencies:
echo   flutter:
echo     sdk: flutter
echo   cupertino_icons: ^1.0.8
echo   http: ^1.2.0
echo   shared_preferences: ^2.3.2
echo   permission_handler: ^11.3.1
echo   flutter_local_notifications: ^18.0.1
echo   url_launcher: ^6.3.1
echo   intl: ^0.19.0
echo.
echo dev_dependencies:
echo   flutter_test:
echo     sdk: flutter
echo   flutter_lints: ^6.0.0
echo.
echo flutter:
echo   uses-material-design: true
echo   assets:
echo     - assets/images/
) > C:\sg\pubspec.yaml

echo [4] pub get 실행 중...
cd /d C:\sg
C:\flutter\bin\flutter.bat pub get

echo [5] 앱 빌드 및 실행 중...
C:\flutter\bin\flutter.bat run -d emulator-5554
