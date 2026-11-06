#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
pm2 status
printf '\nDownloads location:\n'
readlink -f "$HOME/storage/downloads" || true
printf '\nRecent logs:\n'
pm2 logs widget-bot --lines 12 --nostream || true
