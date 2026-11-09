@echo off
cd /d "%~dp0"

echo ============================================
echo  Push card game to tutan-cc/repo
echo  Branch: deck-builder  (main is untouched)
echo ============================================
echo.
echo Git will ask for credentials:
echo   Username: tutan-cc
echo   Password: paste a Personal Access Token (NOT your account password)
echo.
echo Token scope needed: Contents = Read and write
echo Create one at: https://github.com/settings/tokens
echo.

git -c http.sslBackend=openssl push -u mine deck-builder:deck-builder

if %errorlevel% neq 0 (
  echo.
  echo Push failed. Common causes:
  echo   - token lacks Contents: Read and write
  echo   - token expired
  echo   - remote is not tutan-cc/repo
  pause
  exit /b 1
)

echo.
echo Done: https://github.com/tutan-cc/repo/tree/deck-builder
pause
