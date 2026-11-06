#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
pm2 logs widget-bot --lines 60 --nostream
