// Orchestrator: for each source, fetch releases, skip already-published ones,
// transform with attribution, and create Ghost posts (draft by default).
import { loadConfig } from "./config.mjs";
import { fetchReleases } from "./fetchReleases.mjs";
import { toGhostPost } from "./transform.mjs";
import { State } from "./state.mjs";
import { GhostClient } from "./ghost.mjs";

async function main() {
  const cfg = loadConfig();
  const state = new State(cfg.stateFile);
  const ghost = new GhostClient({
    apiUrl: cfg.ghostApiUrl,
    adminApiKey: cfg.ghostApiKey,
    dryRun: cfg.dryRun,
  });

  console.log(
    `Publisher: status=${cfg.status} dryRun=${cfg.dryRun} maxPerRun=${cfg.maxPerRun} sources=${cfg.sources.length}`
  );

  let published = 0;
  for (const source of cfg.sources) {
    if (source.enabled === false) continue;
    console.log(`\n== ${source.name} (${source.type}) ==`);
    let items = [];
    try {
      items = await fetchReleases(source);
    } catch (e) {
      console.warn(`  ! fetch failed: ${e.message}`);
      continue;
    }

    for (const item of items) {
      if (published >= cfg.maxPerRun) break;
      if (state.has(item.url)) continue;

      const post = toGhostPost(item, source, cfg);
      try {
        const result = await ghost.createPost(post);
        state.add(item.url, { title: item.title, slug: result?.slug, status: post.status });
        published++;
        console.log(`  + ${cfg.dryRun ? "[dry-run] " : ""}${post.status}: ${item.title}`);
      } catch (e) {
        console.error(`  ! publish failed for "${item.title}": ${e.message}`);
      }
    }
  }

  state.save();
  console.log(`\nDone. ${cfg.dryRun ? "Would publish" : "Published"} ${published} post(s).`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
