#!/usr/bin/env node
// webhook.js — servidor HTTP que recebe o webhook "post.published" do Ghost e
// dispara a sindicalização automaticamente.
//
// No Ghost Admin → Settings → Integrations → (sua Custom Integration) → Add webhook:
//   Event      : Post published
//   Target URL : https://SEU_HOST:PORTA/webhook/ghost
//   Secret     : (opcional, mas recomendado) → mesmo valor de GHOST_WEBHOOK_SECRET
//
// Config:
//   WEBHOOK_PORT   (padrão 3333)
//   WEBHOOK_PATH   (padrão /webhook/ghost)
//   GHOST_WEBHOOK_SECRET  (se definido, valida a assinatura X-Ghost-Signature)
//
// Uso: node publisher/webhook.js   (deixe rodando; ex.: atrás de um proxy TLS)

import http from "node:http";
import crypto from "node:crypto";
import { log } from "./lib/log.js";
import { get } from "./lib/config.js";
import { syndicate } from "./lib/syndicator.js";

const PORT = Number(get("WEBHOOK_PORT", "3333"));
const PATH = get("WEBHOOK_PATH", "/webhook/ghost");
const SECRET = get("GHOST_WEBHOOK_SECRET");

// Ghost assina com: HMAC-SHA256( `${body}${timestamp}` ) e envia o header
//   X-Ghost-Signature: sha256=<hex>, t=<ms>
function verifySignature(rawBody, header) {
  if (!SECRET) return true; // verificação desligada
  if (!header) return false;
  const m = /sha256=([a-f0-9]+),\s*t=(\d+)/i.exec(header);
  if (!m) return false;
  const [, sig, ts] = m;
  const expected = crypto.createHmac("sha256", SECRET).update(`${rawBody}${ts}`).digest("hex");
  const a = Buffer.from(sig, "hex");
  const b = Buffer.from(expected, "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > 2_000_000) reject(new Error("payload muito grande"));
      else chunks.push(c);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost`);
  if (req.method === "GET" && url.pathname === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ ok: true }));
  }
  if (req.method !== "POST" || url.pathname !== PATH) {
    res.writeHead(404);
    return res.end("not found");
  }

  let rawBody;
  try {
    rawBody = await readBody(req);
  } catch (err) {
    res.writeHead(413);
    return res.end(err.message);
  }

  if (!verifySignature(rawBody, req.headers["x-ghost-signature"])) {
    log.warn("Webhook: assinatura inválida — rejeitado.");
    res.writeHead(401);
    return res.end("invalid signature");
  }

  let post;
  try {
    const payload = JSON.parse(rawBody);
    // Ghost envia { post: { current: {...}, previous: {...} } }
    post = payload?.post?.current || payload?.page?.current || payload?.post || null;
  } catch {
    res.writeHead(400);
    return res.end("invalid json");
  }

  if (!post || !post.title) {
    log.warn("Webhook: payload sem post publicado — ignorado.");
    res.writeHead(200);
    return res.end("no post");
  }

  // Responde já (o Ghost espera um 2xx rápido); sindicaliza em background.
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ received: post.title }));

  log.info(`Webhook: post publicado → "${post.title}"`);
  syndicate(post).catch((err) => log.error(`Sindicalização falhou: ${err.message}`));
});

server.listen(PORT, () => {
  log.ok(`Webhook ouvindo em http://0.0.0.0:${PORT}${PATH}`);
  if (!SECRET) log.warn("GHOST_WEBHOOK_SECRET não definido — assinatura NÃO será verificada.");
});
