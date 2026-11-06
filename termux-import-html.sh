#!/data/data/com.termux/files/usr/bin/bash
# Import HTML edited using Samsung My Files from Download into the running project.
set -euo pipefail
WORK="$HOME/widget-bot-demos"
SOURCE="$HOME/storage/downloads/widget-bot-demos"
[[ -d "$SOURCE" && -d "$WORK" ]] || { echo 'Run setup first.'; exit 1; }
for file in my.html my2.html my3.html; do
  if [[ -f "$SOURCE/$file" ]]; then
    cp "$SOURCE/$file" "$WORK/$file"
    echo "Imported $file"
  fi
done
echo 'Done. Send /my, /my2 or /my3 again. Bot restart is not needed.'
