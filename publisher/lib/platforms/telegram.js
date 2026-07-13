// Telegram adapter — posts to a channel/group via the Bot API.
//   TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID  (ex: @meucanal ou -1001234567890)
// O bot precisa ser admin do canal. Docs: https://core.telegram.org/bots/api
//
// Com imagem usa sendPhoto (legenda até 1024 chars); sem imagem, sendMessage.

import { get, has } from "../config.js";

export const name = "telegram";

export function configured() {
  return has("TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID");
}

const CAPTION_LIMIT = 1024;

function truncate(s, n) {
  return s.length <= n ? s : s.slice(0, n - 1).trimEnd() + "…";
}

export async function post(msg, { dryRun } = {}) {
  const token = get("TELEGRAM_BOT_TOKEN");
  const chatId = get("TELEGRAM_CHAT_ID");
  const usesPhoto = Boolean(msg.image);
  const text = usesPhoto ? truncate(msg.telegram, CAPTION_LIMIT) : msg.telegram;

  if (dryRun) return { dryRun: true, method: usesPhoto ? "sendPhoto" : "sendMessage", text, image: msg.image };

  const method = usesPhoto ? "sendPhoto" : "sendMessage";
  const url = `https://api.telegram.org/bot${token}/${method}`;
  // Plain text (no parse_mode) — evita erros de entidade com "&"/"<" e o
  // Telegram ainda faz auto-preview de URLs cruas.
  const body = usesPhoto
    ? { chat_id: chatId, photo: msg.image, caption: text }
    : { chat_id: chatId, text, disable_web_page_preview: false };

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.text();
  if (!res.ok) throw new Error(`Telegram post failed (${res.status}): ${data}`);
  const json = JSON.parse(data);
  if (!json.ok) throw new Error(`Telegram API error: ${data}`);
  return { id: json.result?.message_id };
}
