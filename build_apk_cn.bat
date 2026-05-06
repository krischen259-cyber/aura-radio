@echo off
chcp 65001 >nul
REM Use Flutter community mirror (China) so Gradle can download engine AARs
REM from storage instead of storage.googleapis.com when direct access fails.
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"

cd /d "%~dp0"
echo FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%
echo PUB_HOSTED_URL=%PUB_HOSTED_URL%
echo.

call flutter pub get
if errorlevel 1 exit /b 1

echo.
echo ========== Building APK (this may take several minutes)... ==========
call flutter build apk
set ERR=%ERRORLEVEL%
echo.
if %ERR% neq 0 (
  echo Build reported error level %ERR%. Searching for any .apk under .\build ...
  dir /s /b build\*.apk 2>nul
  echo.
  echo If an APK exists above, copy it to your phone and install. Otherwise try: call flutter build apk --debug
)
exit /b %ERR%
