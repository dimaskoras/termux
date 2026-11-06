@echo off
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>nul || (echo Node.js не найден. Установи LTS с nodejs.org ^(нужна версия 22.6 или новее^) & pause & exit /b 1)
findstr /c:"PUT_TOKEN_HERE" widget-bot.env >nul && (echo Впиши токен в widget-bot.env & pause & exit /b 1)
node --experimental-strip-types --no-warnings scripts\bot-demos.ts --config widget-bot.env
pause
