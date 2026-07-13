// Turn a Ghost post into per-platform message payloads.

import { get } from "./config.js";

const X_LIMIT = 280;

function stripHtml(html = "") {
  return html
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/\s+/g, " ")
    .trim();
}

function truncate(s, n) {
  if (s.length <= n) return s;
  return s.slice(0, Math.max(0, n - 1)).trimEnd() + "…";
}

// Normalize a Ghost post (Admin or Content API shape) into a flat summary.
export function normalize(post) {
  const siteUrl = (get("SITE_URL") || get("GHOST_URL") || "").replace(/\/+$/, "");
  const url = post.url || (siteUrl && post.slug ? `${siteUrl}/${post.slug}/` : siteUrl);
  const excerpt =
    post.custom_excerpt ||
    post.excerpt ||
    stripHtml(post.html || "").slice(0, 300);
  return {
    title: post.title || "",
    excerpt: excerpt.trim(),
    url,
    image: post.feature_image || null,
    tags: (post.tags || []).map((t) => (typeof t === "string" ? t : t.name)).filter(Boolean),
  };
}

function hashtags(tags, max = 4) {
  return tags
    .slice(0, max)
    .map((t) => "#" + t.replace(/[^\p{L}\p{N}]/gu, ""))
    .filter((h) => h.length > 1)
    .join(" ");
}

// Build all platform variants. Each platform adapter reads what it needs.
export function buildMessages(post) {
  const p = normalize(post);
  const tagLine = hashtags(p.tags);

  // X: hard 280-char budget; reserve room for the URL + a space.
  const xReserve = p.url ? p.url.length + 1 : 0;
  const xText = `${truncate(p.title, X_LIMIT - xReserve)}${p.url ? " " + p.url : ""}`;

  // Facebook / WhatsApp: title + excerpt + link.
  const longBody = [p.title, p.excerpt, p.url].filter(Boolean).join("\n\n");

  // Instagram feed posts cannot carry a clickable link; nudge to bio.
  const igCaption = [p.title, p.excerpt, tagLine, "🔗 Link na bio."]
    .filter(Boolean)
    .join("\n\n");

  return {
    ...p,
    x: xText,
    facebook: longBody,
    whatsapp: longBody,
    telegram: longBody,
    instagram: igCaption,
  };
}

export { stripHtml };
