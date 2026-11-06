#!/data/data/com.termux/files/usr/bin/bash
# Internal launcher. Run from Termux HOME, not shared Android storage.
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TS_FILE="$APP_DIR/scripts/bot-demos.ts"
ENV_FILE="$APP_DIR/widget-bot.env"
if [[ ! -f "$TS_FILE" ]]; then
  echo "ERROR: $TS_FILE not found" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found" >&2
  exit 1
fi
cd "$APP_DIR"
exec node --experimental-strip-types "$TS_FILE" --config "$ENV_FILE"
