// WhatsApp adapter — broadcasts via the WhatsApp Cloud API (Meta).
//   WHATSAPP_PHONE_ID, WHATSAPP_TOKEN, WHATSAPP_RECIPIENTS (comma-separated)
// Docs: https://developers.facebook.com/docs/whatsapp/cloud-api
//
// ⚠️ COMPLIANCE: the Cloud API only delivers to recipients who have opted in.
//   - Inside a 24h customer-service window you may send free-form text.
//   - To initiate a conversation you MUST use an approved message template
//     (set WHATSAPP_TEMPLATE + WHATSAPP_TEMPLATE_LANG). Sending unsolicited
//     bulk messages violates WhatsApp's Business Policy and risks a ban.
// This adapter does NOT scrape group members or message non-consenting users.

import { get, has } from "../config.js";

export const name = "whatsapp";

const GRAPH = get("GRAPH_API_VERSION", "v21.0");

export function configured() {
  return has("WHATSAPP_PHONE_ID", "WHATSAPP_TOKEN", "WHATSAPP_RECIPIENTS");
}

function recipients() {
  return get("WHATSAPP_RECIPIENTS", "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function payloadFor(to, msg) {
  const template = get("WHATSAPP_TEMPLATE");
  if (template) {
    // Template (business-initiated) — text params map to {{1}}, {{2}} ...
    return {
      messaging_product: "whatsapp",
      to,
      type: "template",
      template: {
        name: template,
        language: { code: get("WHATSAPP_TEMPLATE_LANG", "pt_BR") },
        components: [
          {
            type: "body",
            parameters: [
              { type: "text", text: msg.title },
              { type: "text", text: msg.url || "" },
            ],
          },
        ],
      },
    };
  }
  // Free-form text (only valid within an open 24h window).
  return {
    messaging_product: "whatsapp",
    to,
    type: "text",
    text: { preview_url: true, body: msg.whatsapp },
  };
}

export async function post(msg, { dryRun } = {}) {
  const phoneId = get("WHATSAPP_PHONE_ID");
  const token = get("WHATSAPP_TOKEN");
  const to = recipients();
  if (to.length === 0) return { skipped: true, reason: "WHATSAPP_RECIPIENTS vazio." };
  if (dryRun) return { dryRun: true, recipients: to.length, body: msg.whatsapp };

  const url = `https://graph.facebook.com/${GRAPH}/${phoneId}/messages`;
  const results = [];
  for (const n of to) {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify(payloadFor(n, msg)),
    });
    const body = await res.text();
    if (!res.ok) {
      results.push({ to: n, ok: false, error: `${res.status}: ${body}` });
    } else {
      results.push({ to: n, ok: true, id: JSON.parse(body).messages?.[0]?.id });
    }
  }
  const failed = results.filter((r) => !r.ok);
  if (failed.length) {
    const err = new Error(`WhatsApp: ${failed.length}/${to.length} falharam`);
    err.results = results;
    throw err;
  }
  return { sent: results.length };
}
