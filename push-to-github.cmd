@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo  Push card game - tutan-cc/deck-builder-game
echo  remote: cardgame    branch: main
echo ============================================
echo.

git -c http.sslBackend=openssl status --short
echo.

rem commit message: pass it as an argument, or just press Enter for the default
set MSG=%~1
if "%MSG%"=="" set /p MSG=Commit message (enter = default): 
if "%MSG%"=="" set MSG=chore: update

git add -A
git -c http.sslBackend=openssl commit -m "%MSG%"
if errorlevel 1 echo (nothing to commit, or commit failed - still trying to push)

rem credential.username 必须给：本机存了 github.com 和 x-access-token@github.com 两条凭据，
rem 不给的话 git-credential-manager 会弹"Select an account"对话框等人点。
set CFG=-c http.sslBackend=openssl -c credential.username=tutan-cc
rem 本机 github 走本地代理（Clash 127.0.0.1:7897）；代理没开时先试直连
set PXO=-c http.proxy=http://127.0.0.1:7897

echo.
echo Pushing...
set N=0
:try
git %CFG% push cardgame main
if not errorlevel 1 goto ok
echo direct failed, retry via local proxy 127.0.0.1:7897 ...
git %CFG% %PXO% push cardgame main
if not errorlevel 1 goto ok
set /a N+=1
if %N% geq 3 goto fail
echo Attempt %N% failed. Retrying in 3s...
timeout /t 3 >nul
goto try

:ok
echo.
echo Done: https://github.com/tutan-cc/deck-builder-game
pause
exit /b 0

:fail
echo.
echo Push failed 3 times. Common causes:
echo   - local proxy (Clash) is not running: start Clash Verge and try again
echo   - the stored token expired or lacks Contents: Read and write
pause
exit /b 1
