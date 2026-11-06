#!/data/data/com.termux/files/usr/bin/bash
# One-time setup: install PM2, start bot, install boot hook, export visible copy to Download.
set -euo pipefail
APP="widget-bot"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORK="$HOME/widget-bot-demos"
DOWNLOADS="$HOME/storage/downloads/widget-bot-demos"

if [[ ! -d "${PREFIX:-}/bin" ]] || [[ ! -d "$HOME/storage/downloads" ]]; then
  echo 'Error: run inside Termux after termux-setup-storage (grant storage permission).' >&2
  exit 1
fi
if [[ ! -f "$SOURCE/scripts/bot-demos.ts" || ! -f "$SOURCE/widget-bot.env" ]]; then
  echo 'Error: bot-demos.ts or widget-bot.env is missing in the cloned project.' >&2
  exit 1
fi
if [[ "$SOURCE" != "$WORK" ]]; then
  echo '[1/6] Copying project to private Termux HOME...'
  mkdir -p "$WORK"
  cp -R "$SOURCE"/. "$WORK"/
else
  echo '[1/6] Project is already in Termux HOME.'
fi
chmod 700 "$WORK"
chmod 600 "$WORK/widget-bot.env"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo '[2/6] Installing Node.js...'
  pkg install -y nodejs
fi
NODE_MAJOR="$(node -p 'Number(process.versions.node.split(".")[0])')"
if (( NODE_MAJOR < 22 )); then
  echo "Error: Node.js version 22+ required, found $(node -v). Run: pkg upgrade" >&2
  exit 1
fi
node --experimental-strip-types --check "$WORK/scripts/bot-demos.ts"
if ! command -v pm2 >/dev/null 2>&1; then
  echo '[3/6] Installing PM2...'
  npm install -g pm2
else
  echo '[3/6] PM2 already installed.'
fi

if [[ -d "$HOME/storage/downloads" ]]; then
  echo '[4/6] Creating visible project copy in Download...'
  mkdir -p "$DOWNLOADS"
  (cd "$WORK" && tar --exclude='./.git' --exclude='./node_modules' -cf - .) | (cd "$DOWNLOADS" && tar -xf -)
fi

echo '[5/6] Installing Termux:Boot hook...'
mkdir -p "$HOME/.termux/boot"
cat > "$HOME/.termux/boot/90-widget-bot" <<'BOOT'
#!/data/data/com.termux/files/usr/bin/sh
export HOME=/data/data/com.termux/files/home
export PATH=/data/data/com.termux/files/usr/bin:$PATH
termux-wake-lock
sleep 15
pm2 resurrect >> "$HOME/widget-bot-boot.log" 2>&1
BOOT
chmod 700 "$HOME/.termux/boot/90-widget-bot"

echo '[6/6] Starting bot in the background...'
termux-wake-lock || true
if pm2 describe "$APP" >/dev/null 2>&1; then
  pm2 delete "$APP"
fi
pm2 start "$WORK/termux-run.sh" --name "$APP" --interpreter bash --cwd "$WORK"
pm2 save
pm2 status
printf '\nSetup finished!\nDownload copy: %s\nRunning project: %s\n' "$DOWNLOADS" "$WORK"
printf 'View logs: bash %s/termux-logs.sh\n' "$WORK"
printf 'For boot: install Termux:Boot from the same app source, then open it once.\n'
printf 'Stop the Windows bot to avoid competing getUpdates requests.\n'
