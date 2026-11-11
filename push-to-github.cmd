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

echo.
echo Pushing...
set TRIES=0
:retry
git -c http.sslBackend=openssl push cardgame main
if not errorlevel 1 goto ok
set /a TRIES+=1
if %TRIES% geq 3 goto fail
echo Attempt %TRIES% failed (usually the local proxy dropping TLS). Retrying...
timeout /t 2 >nul
goto retry

:ok
echo.
echo Done: https://github.com/tutan-cc/deck-builder-game
pause
exit /b 0

:fail
echo.
echo Push failed 3 times. Common causes:
echo   - github goes through a local proxy here, TLS handshake fails at random: just double-click again later
echo   - the stored token expired or lacks Contents: Read and write
pause
exit /b 1
