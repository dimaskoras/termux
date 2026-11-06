#!/data/data/com.termux/files/usr/bin/bash
# Copies current working project (including state and env) into Samsung Download.
set -euo pipefail
WORK="$HOME/widget-bot-demos"
DEST="$HOME/storage/downloads/widget-bot-demos"
[[ -f "$WORK/scripts/bot-demos.ts" ]] || { echo 'Working project not found'; exit 1; }
[[ -d "$HOME/storage/downloads" ]] || { echo 'Run termux-setup-storage first'; exit 1; }
mkdir -p "$DEST"
(cd "$WORK" && tar --exclude='./.git' --exclude='./node_modules' -cf - .) | (cd "$DEST" && tar -xf -)
echo "Copied to $DEST"
echo 'Warning: this copy includes widget-bot.env (Telegram token).'
