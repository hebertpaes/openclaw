// Fetch and normalize releases for one source (RSS feed or HTML listing).
import { parseFeed } from "./rss.mjs";
import { extractLinks, parseArticle, extractBody } from "./html.mjs";

const UA = "odiapolitico-publisher/1.0 (+https://odiapolitico.com.br)";

async function getText(url) {
  const res = await fetch(url, { headers: { "User-Agent": UA, Accept: "*/*" } });
  if (!res.ok) throw new Error(`GET ${url} -> ${res.status}`);
  return res.text();
}

/**
 * @param {object} source
 *   { name, type: "rss"|"html", url, tag, attribution,
 *     linkPattern?, bodySelector?, maxArticles? }   // html-only fields
 * @returns {Promise<Array>} normalized items (newest first when dated)
 */
export async function fetchReleases(source) {
  if (source.type === "rss") {
    const xml = await getText(source.url);
    return sortNewest(parseFeed(xml));
  }

  if (source.type === "html") {
    const listing = await getText(source.url);
    const links = extractLinks(listing, source.url, source.linkPattern).slice(
      0,
      source.maxArticles || 10
    );
    const items = [];
    for (const link of links) {
      try {
        const html = await getText(link);
        const item = parseArticle(html, link);
        const body = extractBody(html, source.bodySelector);
        if (body) item.contentHtml = body;
        if (item.title && item.url) items.push(item);
      } catch (e) {
        console.warn(`  ! skip ${link}: ${e.message}`);
      }
    }
    return sortNewest(items);
  }

  throw new Error(`Unknown source type "${source.type}" for ${source.name}`);
}

function sortNewest(items) {
  return items.slice().sort((a, b) => {
    const ta = a.date ? a.date.getTime() : 0;
    const tb = b.date ? b.date.getTime() : 0;
    return tb - ta;
  });
}
