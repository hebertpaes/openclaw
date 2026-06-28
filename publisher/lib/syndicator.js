// Orchestrator — fan a Ghost post out to every enabled & configured platform.

import { log } from "./log.js";
import { bool, get } from "./config.js";
import { buildMessages } from "./format.js";

import * as x from "./platforms/x.js";
import * as facebook from "./platforms/facebook.js";
import * as instagram from "./platforms/instagram.js";
import * as whatsapp from "./platforms/whatsapp.js";

const ALL = { x, facebook, instagram, whatsapp };

// A platform runs when: not globally disabled (PLATFORM_<NAME>=0 to opt out)
// AND it has the credentials it needs.
function selected(only) {
  const wanted = only && only.length ? new Set(only) : null;
  return Object.values(ALL).filter((p) => {
    if (wanted && !wanted.has(p.name)) return false;
    if (!bool(`PLATFORM_${p.name.toUpperCase()}`, true)) return false;
    return true;
  });
}

export async function syndicate(post, { dryRun = false, only = null } = {}) {
  const msg = buildMessages(post);
  log.info(`Sindicalizando: "${msg.title}"`);
  if (msg.url) log.info(`URL: ${msg.url}`);
  if (dryRun) log.warn("DRY-RUN — nada será enviado.");

  const platforms = selected(only);
  const summary = [];

  for (const p of platforms) {
    if (!p.configured()) {
      log.warn(`${p.name}: pulado (credenciais ausentes).`);
      summary.push({ platform: p.name, status: "unconfigured" });
      continue;
    }
    try {
      const r = await p.post(msg, { dryRun });
      if (r?.skipped) {
        log.warn(`${p.name}: pulado — ${r.reason}`);
        summary.push({ platform: p.name, status: "skipped", reason: r.reason });
      } else if (r?.dryRun) {
        log.ok(`${p.name}: OK (dry-run)`);
        summary.push({ platform: p.name, status: "dry-run", detail: r });
      } else {
        log.ok(`${p.name}: publicado ${r?.id ? "(" + r.id + ")" : ""}`);
        summary.push({ platform: p.name, status: "ok", detail: r });
      }
    } catch (err) {
      log.error(`${p.name}: ERRO — ${err.message}`);
      summary.push({ platform: p.name, status: "error", error: err.message });
    }
  }
  return summary;
}

export function platformNames() {
  return Object.keys(ALL);
}
