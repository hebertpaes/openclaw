#!/usr/bin/env node
// syndicate.js — pega um post já publicado no Ghost e distribui nas redes.
//
// Uso:
//   node syndicate.js                       # último post publicado
//   node syndicate.js --slug minha-materia  # por slug
//   node syndicate.js --id 65f...           # por id
//   node syndicate.js --dry-run --only x,whatsapp

import { log, die } from "./lib/log.js";
import { latestPost, getPost } from "./lib/ghost.js";
import { syndicate } from "./lib/syndicator.js";

function parseArgs(argv) {
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (!t.startsWith("--")) continue;
    const key = t.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) flags[key] = true;
    else { flags[key] = next; i++; }
  }
  return flags;
}

const f = parseArgs(process.argv.slice(2));

if (f.help) {
  console.log(`syndicate.js — distribui um post do Ghost nas redes

  (sem args)        usa o último post publicado
  --slug <slug>     post por slug
  --id <id>         post por id
  --dry-run         simula (não envia)
  --only <a,b>      só essas plataformas (x,facebook,instagram,whatsapp)
`);
  process.exit(0);
}

try {
  let post;
  if (f.id || f.slug) {
    post = await getPost({ id: f.id || undefined, slug: f.slug || undefined });
  } else {
    post = await latestPost();
  }
  if (!post) die("Nenhum post encontrado no Ghost.");
  log.info(`Post selecionado: "${post.title}"`);

  const only = f.only ? String(f.only).split(",").map((s) => s.trim()) : null;
  await syndicate(post, { dryRun: !!f["dry-run"], only });
} catch (err) {
  die(err.message);
}
