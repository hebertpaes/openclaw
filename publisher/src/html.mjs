// Zero-dependency HTML fallback for sources without an RSS feed.
// Best-effort: pull article links from a listing page, then read each article's
// Open Graph metadata (present on most gov/news CMSes). Tune per source in
// sources.json — this cannot be verified against every site from here.

function meta(html, prop) {
  // <meta property="og:title" content="..."> or name="..."
  const re = new RegExp(
    `<meta\\b[^>]*(?:property|name)=["']${prop}["'][^>]*content=["']([^"']*)["']`,
    "i"
  );
  const m = html.match(re) || html.match(
    new RegExp(`<meta\\b[^>]*content=["']([^"']*)["'][^>]*(?:property|name)=["']${prop}["']`, "i")
  );
  return m ? m[1] : "";
}

function absolutize(href, base) {
  try {
    return new URL(href, base).toString();
  } catch {
    return href;
  }
}

/** Extract article links from a listing page, matched by a regex string. */
export function extractLinks(listingHtml, baseUrl, linkPattern) {
  const re = new RegExp(linkPattern || "", "i");
  const hrefs = [...listingHtml.matchAll(/<a\b[^>]*href=["']([^"'#]+)["']/gi)].map((m) => m[1]);
  const seen = new Set();
  const out = [];
  for (const h of hrefs) {
    const abs = absolutize(h, baseUrl);
    if (linkPattern && !re.test(abs)) continue;
    if (seen.has(abs)) continue;
    seen.add(abs);
    out.push(abs);
  }
  return out;
}

/** Parse a single article page into a normalized item using Open Graph tags. */
export function parseArticle(html, url) {
  const title = meta(html, "og:title") ||
    (html.match(/<title[^>]*>([\s\S]*?)<\/title>/i) || [])[1] || "";
  const image = meta(html, "og:image");
  const description = meta(html, "og:description") || meta(html, "description");
  const dateStr =
    meta(html, "article:published_time") ||
    meta(html, "og:updated_time") ||
    (html.match(/<time\b[^>]*datetime=["']([^"']+)["']/i) || [])[1] || "";
  const date = dateStr ? new Date(dateStr) : null;

  return {
    title: title.trim(),
    url,
    // Without a per-site body selector we publish the description as the body;
    // set source.bodySelector to capture more (see fetchReleases.mjs).
    contentHtml: description ? `<p>${description}</p>` : "",
    excerpt: description.replace(/\s+/g, " ").trim().slice(0, 300),
    image: image ? absolutize(image, url) : "",
    date: date && !isNaN(date.getTime()) ? date : null,
  };
}

/** Optional: pull inner HTML of the first element matching a tag+class. */
export function extractBody(html, bodySelector) {
  if (!bodySelector) return "";
  // bodySelector like "div.article-content" or "article".
  const m = String(bodySelector).match(/^(\w+)(?:\.([\w-]+))?$/);
  if (!m) return "";
  const [, tagName, className] = m;
  const re = className
    ? new RegExp(`<${tagName}\\b[^>]*class=["'][^"']*\\b${className}\\b[^"']*["'][^>]*>([\\s\\S]*?)<\\/${tagName}>`, "i")
    : new RegExp(`<${tagName}\\b[^>]*>([\\s\\S]*?)<\\/${tagName}>`, "i");
  const found = html.match(re);
  return found ? found[1].trim() : "";
}
