# Samsung Termux: Telegram widget bot (/my, /my2, /my3)

This package assumes the repository includes:
- `scripts/bot-demos.ts`
- `widget-bot.env` with `TW_BOT_TOKEN=...`
- `my.html`, `my2.html`, `my3.html`

## Phone setup (only once)

You already ran `termux-setup-storage` and installed Node.js and Git.
Use a public repository or GitHub authentication for private repositories.

```sh
cd ~
git clone -b YOUR_BRANCH https://github.com/dimaskoras/termux.git widget-bot-demos
cd ~/widget-bot-demos
bash termux-setup.sh
```

`YOUR_BRANCH` is the actual name of the new branch you pushed.

The installer:
- checks Node.js >=22 (built-in TypeScript type stripping), installs PM2 if missing;
- checks config and syntax, starts PM2 process `widget-bot`;
- adds boot hook `~/.termux/boot/90-widget-bot`;
- makes a visible copy in `Download/widget-bot-demos`.

Install **Termux:Boot** from the same app source as Termux and open it at least once.
On Samsung, set Termux and Termux:Boot battery management to **Unrestricted**.

**Do not run the same bot with the same token on the PC at the same time:** both long-polling processes conflict.

## Paths on Samsung

- Android physical path: `/storage/emulated/0/Download`
- Shortcut: `$HOME/storage/downloads`
- Actual path check: `readlink -f ~/storage/downloads`
- Visible project copy: `~/storage/downloads/widget-bot-demos`
- Executable project: `~/widget-bot-demos`

Git, npm, and executable scripts should run in the Termux HOME, not the shared Download storage.

## Commands (from `~/widget-bot-demos`)

```sh
bash termux-start.sh
bash termux-stop.sh
bash termux-status.sh
bash termux-logs.sh
bash termux-update.sh
bash termux-backup-to-downloads.sh
bash termux-import-html.sh
```

`termux-update.sh` gets the latest pushed commit from the checked-out branch, restarts the bot, then copies it to Download.
`termux-import-html.sh` copies edited HTML files **from Download into the working project**; `/my3` immediately uses edited HTML.
`termux-backup-to-downloads.sh` copies the working folder back **to Download**, including the local state file and env.

The Download copy is intended for convenient access and backups; it is **not** the live running directory.

## Check startup after reboot

```
pm2 status
pm2 logs widget-bot --lines 40 --nostream
```

Boot autostart only works if the separate Termux:Boot app is installed and opened at least once. Android may still kill Termux despite Wake Lock and battery exemptions; 24/7 uptime is not guaranteed.

## Important security note

Publishing `widget-bot.env` with a live Telegram token on a public GitHub branch exposes your bot. Prefer a private repository or transfer config separately. If a token was ever publicly pushed, revoke/rotate it in BotFather; deleting it from the latest commit is not enough.

Uninstalling Termux removes its private data (installed packages, PM2, working project). The visible Download copy typically remains, since it is stored in Android shared storage.
