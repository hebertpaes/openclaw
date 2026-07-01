// Load configuration from the environment + sources.json.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

function bool(v, dflt = false) {
  if (v == null || v === "") return dflt;
  return /^(1|true|yes|on)$/i.test(String(v));
}

export function loadConfig(env = process.env) {
  const sourcesFile = env.SOURCES_FILE || path.join(ROOT, "sources.json");
  const sources = JSON.parse(fs.readFileSync(sourcesFile, "utf8"));

  return {
    ghostApiUrl: env.GHOST_ADMIN_API_URL || "",
    ghostApiKey: env.GHOST_ADMIN_API_KEY || "",
    // Safe default: create DRAFTS for editorial review. Set to "published" for full auto.
    status: (env.POST_STATUS || "draft").toLowerCase() === "published" ? "published" : "draft",
    dryRun: bool(env.DRY_RUN, false),
    maxPerRun: Number(env.MAX_PER_RUN || 5),
    stateFile: env.STATE_FILE || path.join(ROOT, "state", "published.json"),
    defaultTags: sources.defaults?.tags || [],
    sources: sources.sources || [],
  };
}
