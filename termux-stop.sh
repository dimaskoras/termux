#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
command -v pm2 >/dev/null || { echo 'PM2 is not installed'; exit 1; }
if pm2 describe widget-bot >/dev/null 2>&1; then
  pm2 delete widget-bot
  pm2 save --force
else
  echo 'Bot already stopped.'
fi
pm2 status
# Wake lock is not released automatically: other Termux jobs may need it.
