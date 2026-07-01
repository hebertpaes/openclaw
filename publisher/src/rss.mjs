// Zero-dependency, tolerant RSS 2.0 / Atom parser.
// Not a full XML parser — extracts the fields we need from press-office feeds.

function stripCdata(s) {
  if (s == null) return "";
  return String(s).replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1").trim();
}

function decodeEntities(s) {
  return String(s)
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#0?39;/g, "'").replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

function tag(block, name) {
  // First <name ...>...</name>, CDATA-aware. Namespaced names allowed (e.g. content:encoded).
  const re = new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${name}>`, "i");
  const m = block.match(re);
  return m ? stripCdata(m[1]) : "";
}

function attr(block, name, attrName) {
  const re = new RegExp(`<${name}\\b[^>]*\\b${attrName}=["']([^"']+)["'][^>]*>`, "i");
  const m = block.match(re);
  return m ? m[1] : "";
}

function firstImgFromHtml(html) {
  const m = String(html).match(/<img\b[^>]*\bsrc=["']([^"']+)["']/i);
  return m ? m[1] : "";
}

/** Parse a feed string into normalized items. */
export function parseFeed(xml) {
  const isAtom = /<feed[\s>]/i.test(xml) && !/<rss[\s>]/i.test(xml);
  const itemRe = isAtom ? /<entry\b[\s\S]*?<\/entry>/gi : /<item\b[\s\S]*?<\/item>/gi;
  const blocks = xml.match(itemRe) || [];

  return blocks.map((block) => {
    const title = decodeEntities(tag(block, "title"));

    let link = "";
    if (isAtom) {
      // <link href="..."/> (prefer rel="alternate" or the first href)
      link =
        (block.match(/<link\b[^>]*rel=["']alternate["'][^>]*href=["']([^"']+)["']/i) || [])[1] ||
        (block.match(/<link\b[^>]*href=["']([^"']+)["']/i) || [])[1] ||
        "";
    } else {
      link = tag(block, "link") || attr(block, "guid", "isPermaLink") && tag(block, "guid");
      if (!link) link = tag(block, "guid");
    }

    const content =
      tag(block, "content:encoded") ||
      tag(block, "content") || // atom
      tag(block, "description") ||
      tag(block, "summary");

    const dateStr =
      tag(block, "pubDate") || tag(block, "published") || tag(block, "updated") || tag(block, "dc:date");
    const date = dateStr ? new Date(dateStr) : null;

    // Image: media:content / enclosure / first <img> in the content.
    const image =
      attr(block, "media:content", "url") ||
      attr(block, "media:thumbnail", "url") ||
      attr(block, "enclosure", "url") ||
      firstImgFromHtml(content) ||
      "";

    const description = decodeEntities(tag(block, "description") || tag(block, "summary"));

    return {
      title,
      url: (link || "").trim(),
      contentHtml: content,
      excerpt: description.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim().slice(0, 300),
      image: image.trim(),
      date: date && !isNaN(date.getTime()) ? date : null,
    };
  }).filter((it) => it.title && it.url);
}
