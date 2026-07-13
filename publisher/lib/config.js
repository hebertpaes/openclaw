// Configuration loader.
//
// Loads (in order, later does NOT override earlier):
//   1. process.env  (highest priority — CI / shell exports)
//   2. publisher/config.env   (gitignored local secrets, "export KEY=value")
//
// The "export " prefix is optional so the same file can be `source`d by bash.

import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const ROOT = join(here, "..");

function parseEnvFile(path) {
  const out = {};
  const text = readFileSync(path, "utf8");
  for (let line of text.split("\n")) {
    line = line.trim();
    if (!line || line.startsWith("#")) continue;
    line = line.replace(/^export\s+/, "");
    const eq = line.indexOf("=");
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    let val = line.slice(eq + 1).trim();
    // Strip a single layer of matching quotes.
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

const fileEnv = (() => {
  const custom = process.env.PUBLISHER_CONFIG;
  const candidates = custom ? [custom] : [join(ROOT, "config.env")];
  for (const p of candidates) {
    if (existsSync(p)) return parseEnvFile(p);
  }
  return {};
})();

// Merge: process.env wins over the file.
const env = { ...fileEnv, ...process.env };

export function get(key, fallback = undefined) {
  const v = env[key];
  return v === undefined || v === "" ? fallback : v;
}

export function bool(key, fallback = false) {
  const v = get(key);
  if (v === undefined) return fallback;
  return /^(1|true|yes|on)$/i.test(v);
}

export function require_(key) {
  const v = get(key);
  if (v === undefined) throw new Error(`Missing required config: ${key}`);
  return v;
}

// True when every listed key has a non-empty value (i.e. platform is configured).
export function has(...keys) {
  return keys.every((k) => get(k) !== undefined);
}

export { env };
