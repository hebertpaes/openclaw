#!/usr/bin/env node
// publish.js — cria um post no Ghost e (opcionalmente) sindicaliza para as redes.
//
// Uso:
//   node publish.js --title "Manchete" --file artigo.html [--tags a,b] \
//        [--image https://.../capa.jpg] [--status published|draft] \
//        [--no-syndicate] [--dry-run] [--only x,facebook]
//
//   node publish.js --title "Manchete" --html "<p>corpo</p>"

import { readFileSync } from "node:fs";
import { log, die } from "./lib/log.js";
import { createPost } from "./lib/ghost.js";
import { syndicate } from "./lib/syndicator.js";

function parseArgs(argv) {
  const a = { flags: {} };
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (t.startsWith("--")) {
      const key = t.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith("--")) {
        a.flags[key] = true;
      } else {
        a.flags[key] = next;
        i++;
      }
    }
  }
  return a.flags;
}

const f = parseArgs(process.argv.slice(2));

if (f.help || (!f.title && !f.file)) {
  console.log(`publish.js — cria post no Ghost + sindicaliza

  --title <txt>        título do post (obrigatório)
  --file <path>        arquivo HTML com o corpo
  --html <txt>         corpo HTML inline (alternativa a --file)
  --tags <a,b,c>       tags separadas por vírgula
  --image <url>        feature image (capa)
  --excerpt <txt>      resumo (custom_excerpt)
  --status <s>         published (padrão) | draft
  --no-syndicate       só cria no Ghost, não posta nas redes
  --dry-run            simula a sindicalização (não envia)
  --only <a,b>         sindicaliza só nessas plataformas (x,facebook,instagram,whatsapp)
`);
  process.exit(f.help ? 0 : 1);
}

try {
  const html = f.file ? readFileSync(f.file, "utf8") : (f.html || "");

  const postInput = {
    title: f.title,
    html,
    status: f.status || "published",
  };
  if (f.tags) postInput.tags = String(f.tags).split(",").map((t) => ({ name: t.trim() })).filter((t) => t.name);
  if (f.image) postInput.feature_image = f.image;
  if (f.excerpt) postInput.custom_excerpt = f.excerpt;

  log.info(`Criando post no Ghost: "${f.title}" (${postInput.status})`);
  const created = await createPost(postInput);
  log.ok(`Ghost: post ${created.status} — ${created.url || created.id}`);

  if (f["no-syndicate"] || postInput.status !== "published") {
    if (postInput.status !== "published") log.warn("Status != published → sindicalização ignorada.");
    process.exit(0);
  }

  const only = f.only ? String(f.only).split(",").map((s) => s.trim()) : null;
  await syndicate(created, { dryRun: !!f["dry-run"], only });
} catch (err) {
  die(err.message);
}
