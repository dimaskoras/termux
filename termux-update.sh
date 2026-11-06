#!/data/data/com.termux/files/usr/bin/bash
# Update tracked files from the current remote branch and restart PM2 bot.
set -euo pipefail
WORK="$HOME/widget-bot-demos"
[[ -d "$WORK/.git" ]] || { echo 'Git repository missing inside Termux HOME. Clone into ~/widget-bot-demos first.' >&2; exit 1; }
cd "$WORK"
BRANCH="$(git branch --show-current)"
[[ -n "$BRANCH" ]] || { echo 'Detached HEAD: select a branch first.' >&2; exit 1; }
echo "Updating branch: $BRANCH"
git pull --ff-only
echo 'Git update completed.'
if pm2 describe widget-bot >/dev/null 2>&1; then
  pm2 restart widget-bot
fi
bash "$WORK/termux-backup-to-downloads.sh"
pm2 status
