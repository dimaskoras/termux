// Telegram widget bot: only /my, /my2 and /my3.
// Each command reads its HTML file from the project root (next to start.bat).
// Files are re-read on each command, so editing an HTML file needs no bot restart.
//
// Run: corepack pnpm tsx scripts/bot-demos.ts [--config <file>]
// Config: ~/.config/widget-sandbox/widget-bot.env
// Required: TW_BOT_TOKEN
// Optional: TW_BOT_API, TW_BOT_TEST_ENV=1

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const opt = (name: string) => (args.includes(name) ? args[args.indexOf(name) + 1] : undefined);
const die = (message: string): never => {
  console.error(`widget-bot: ${message}`);
  process.exit(1);
};

// ---- Bot API configuration

const CONFIG = opt('--config') ?? path.join(os.homedir(), '.config', 'widget-sandbox', 'widget-bot.env');

function loadConfig() {
  const values: Record<string, string> = {};
  if (!fs.existsSync(CONFIG)) die(`no config ${CONFIG}`);

  for (const line of fs.readFileSync(CONFIG, 'utf8').split('\n')) {
    const match = /^\s*(?:export\s+)?([A-Z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (match && !line.trim().startsWith('#')) {
      values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
    }
  }

  const get = (key: string) => process.env[key] || values[key] || '';
  const token = get('TW_BOT_TOKEN') || die(`no TW_BOT_TOKEN in ${CONFIG}`);
  const base = (get('TW_BOT_API') || 'https://api.telegram.org').replace(/\/+$/, '');
  return {
    token,
    url: get('TW_BOT_TEST_ENV') === '1' ? `${base}/bot${token}/test` : `${base}/bot${token}`,
  };
}

const cfg = loadConfig();

async function api(method: string, params: Record<string, unknown> = {}): Promise<any> {
  for (;;) {
    let body: any;
    try {
      const response = await fetch(`${cfg.url}/${method}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(params),
      });
      body = await response.json();
    } catch (error) {
      throw new Error(`${method}: ${String((error as Error).message).split(cfg.token).join('<token>')}`);
    }

    if (body.ok) return body.result;

    const wait = body.parameters?.retry_after;
    if (wait) {
      await new Promise((resolve) => setTimeout(resolve, wait * 1000 + 200));
      continue;
    }
    throw new Error(`${method}: ${body.description}`);
  }
}

// ---- Only three commands

const WIDGET_FILES: Record<string, string> = {
  '/my': 'my.html',
  '/my2': 'my2.html',
  '/my3': 'my3.html',
};

async function onMessage(message: any) {
  const command = String(message.text ?? '').trim().split(/\s+/)[0].split('@')[0];
  const file = WIDGET_FILES[command];
  if (!file) return;

  const chat_id = message.chat.id;
  try {
    await api('sendWidget', {
      chat_id,
      html: fs.readFileSync(path.join(ROOT, file), 'utf8'),
      allow_queries: true,
      chat_data: JSON.stringify({ t: 'start' }),
    });
    console.log(`${command} in ${message.chat.type} ${chat_id}`);
  } catch (error) {
    await api('sendMessage', {
      chat_id,
      text: `${file}: ${(error as Error).message}`,
    });
  }
}

// ---- Requests from my.html, my2.html and my3.html
// Each HTML widget can call TelegramWidget.request('my:set:...'),
// TelegramWidget.request('my2:set:...') or TelegramWidget.request('my3:set:...').
// :set: saves up to 1000 characters to that message's chat_data.
// Any other request with a matching prefix is echoed back, as before.

const keyOf = (query: any) => query.inline_message_id
  ? { inline_message_id: query.inline_message_id }
  : { chat_id: query.chat.id, message_id: query.message_id };

async function onQuery(query: any, fromCopy: boolean): Promise<unknown> {
  const data = String(query.data ?? '');
  const kind = data.split(':')[0];
  if (!['my', 'my2', 'my3'].includes(kind)) return { err: 'Unknown request' };

  const prefix = `${kind}:set:`;
  if (!fromCopy && data.startsWith(prefix)) {
    await api('editMessageWidgetData', {
      ...keyOf(query),
      chat_data: data.slice(prefix.length).slice(0, 1000),
    });
  }

  return {
    ok: 1,
    echo: data,
    from: String(query.from?.first_name ?? 'Someone').slice(0, 16),
    t: new Date().toTimeString().slice(0, 5),
  };
}

// ---- Polling

async function main() {
  const me = await api('getMe');

  // Replace the bot's default command menu with only these commands.
  try {
    await api('setMyCommands', {
      commands: [
        { command: 'my', description: 'Открыть my.html' },
        { command: 'my2', description: 'Открыть my2.html' },
        { command: 'my3', description: 'Открыть my3.html' },
      ],
    });
  } catch (error) {
    console.error(`Could not update bot command menu: ${(error as Error).message}`);
  }

  console.log(`widget-bot: @${me.username}, commands: /my, /my2, /my3; Ctrl-C to stop`);

  let offset = 0;
  for (;;) {
    let updates: any[] = [];
    try {
      updates = await api('getUpdates', {
        offset,
        timeout: 30,
        allowed_updates: ['message', 'widget_query', 'shared_widget_query'],
      });
    } catch (error) {
      console.error((error as Error).message);
      await new Promise((resolve) => setTimeout(resolve, 3000));
      continue;
    }

    for (const update of updates) {
      offset = update.update_id + 1;
      try {
        if (update.message) {
          await onMessage(update.message);
        } else if (update.widget_query || update.shared_widget_query) {
          const query = update.widget_query ?? update.shared_widget_query;
          let answer: unknown;
          try {
            answer = await onQuery(query, !update.widget_query);
          } catch (error) {
            console.error(`${query.data}: ${(error as Error).message}`);
            answer = { err: 'The bot failed. Try again' };
          }
          await api('answerWidgetQuery', {
            widget_query_id: query.id,
            data: JSON.stringify(answer),
          });
        }
      } catch (error) {
        console.error((error as Error).message);
      }
    }
  }
}

main().catch((error) => die((error as Error).message));
