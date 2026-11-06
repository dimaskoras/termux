#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
WORK="$HOME/widget-bot-demos"
command -v pm2 >/dev/null || { echo 'Run: bash termux-setup.sh first'; exit 1; }
[[ -f "$WORK/termux-run.sh" ]] || { echo 'Missing working project in Termux HOME'; exit 1; }
termux-wake-lock || true
if pm2 describe widget-bot >/dev/null 2>&1; then
  pm2 restart widget-bot
else
  pm2 start "$WORK/termux-run.sh" --name widget-bot --interpreter bash --cwd "$WORK"
fi
pm2 save
pm2 status
