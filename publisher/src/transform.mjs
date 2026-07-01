// Turn a normalized release into a Ghost post object, always attributing the
// source (link + canonical_url) as required for reusing press-office content.

function fmtDate(d) {
  if (!(d instanceof Date) || isNaN(d.getTime())) return "";
  return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit", year: "numeric" });
}

/**
 * @param {object} item    { title, url, contentHtml, excerpt, image, date }
 * @param {object} source  { name, attribution, tag }
 * @param {object} cfg     { status, defaultTags }
 */
export function toGhostPost(item, source, cfg) {
  const attributionName = source.attribution || source.name;
  const when = fmtDate(item.date);
  const attributionHtml =
    `<hr>\n<p><em>Fonte: <a href="${item.url}" rel="nofollow noopener" target="_blank">${attributionName}</a>` +
    (when ? ` — publicado originalmente em ${when}` : "") +
    `. Conteúdo reproduzido com créditos à assessoria de origem.</em></p>`;

  const bodyHtml = (item.contentHtml || `<p>${item.excerpt || ""}</p>`) + "\n" + attributionHtml;

  const tags = [];
  if (source.tag) tags.push({ name: source.tag });
  for (const t of cfg.defaultTags || []) tags.push({ name: t });

  const post = {
    title: item.title,
    html: bodyHtml,
    status: cfg.status || "draft",
    tags,
    canonical_url: item.url, // attribute + avoid duplicate-content SEO penalty
  };
  if (item.image) post.feature_image = item.image;
  if (item.excerpt) post.custom_excerpt = item.excerpt.slice(0, 300);
  return post;
}
