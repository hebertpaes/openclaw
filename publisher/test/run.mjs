// Zero-dependency tests: node test/run.mjs
import assert from "node:assert";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { makeToken } from "../src/ghost.mjs";
import { parseFeed } from "../src/rss.mjs";
import { toGhostPost } from "../src/transform.mjs";
import { State } from "../src/state.mjs";

let passed = 0;
function test(name, fn) {
  fn();
  passed++;
  console.log(`ok - ${name}`);
}

// --- Ghost JWT -------------------------------------------------------------
test("makeToken builds a verifiable HS256 JWT with kid + aud", () => {
  const id = "5f...abc";
  const secretHex = "0123456789abcdef0123456789abcdef";
  const token = makeToken(`${id}:${secretHex}`, 1000);
  const [h, p, sig] = token.split(".");
  const header = JSON.parse(Buffer.from(h, "base64url"));
  const payload = JSON.parse(Buffer.from(p, "base64url"));
  assert.equal(header.alg, "HS256");
  assert.equal(header.kid, id);
  assert.equal(payload.aud, "/admin/");
  assert.equal(payload.iat, 1000);
  assert.equal(payload.exp, 1000 + 300);
  const expected = crypto
    .createHmac("sha256", Buffer.from(secretHex, "hex"))
    .update(`${h}.${p}`)
    .digest("base64url");
  assert.equal(sig, expected, "signature must verify");
});

test("makeToken rejects a malformed key", () => {
  assert.throws(() => makeToken("nocolon"));
});

// --- RSS parsing -----------------------------------------------------------
test("parseFeed extracts items with CDATA, image and date", () => {
  const xml = `<?xml version="1.0"?><rss><channel>
    <item>
      <title><![CDATA[Governo anuncia obra]]></title>
      <link>https://www.secom.mt.gov.br/noticias/obra-123</link>
      <pubDate>Mon, 16 Jun 2026 12:00:00 -0400</pubDate>
      <description><![CDATA[<p>Texto do <b>release</b> com <img src="https://x/img.jpg"/>.</p>]]></description>
    </item>
    <item>
      <title>Sem imagem</title>
      <link>https://www.secom.mt.gov.br/noticias/nota-9</link>
      <enclosure url="https://x/cover.png" type="image/png"/>
      <description>Nota simples</description>
    </item>
  </channel></rss>`;
  const items = parseFeed(xml);
  assert.equal(items.length, 2);
  assert.equal(items[0].title, "Governo anuncia obra");
  assert.equal(items[0].url, "https://www.secom.mt.gov.br/noticias/obra-123");
  assert.equal(items[0].image, "https://x/img.jpg");
  assert.ok(items[0].date instanceof Date && !isNaN(items[0].date));
  assert.equal(items[1].image, "https://x/cover.png");
});

test("parseFeed handles Atom entries", () => {
  const xml = `<feed xmlns="http://www.w3.org/2005/Atom">
    <entry><title>Atom item</title>
      <link rel="alternate" href="https://p.mt.gov.br/a/1"/>
      <updated>2026-06-16T10:00:00Z</updated>
      <summary>resumo</summary></entry>
  </feed>`;
  const items = parseFeed(xml);
  assert.equal(items.length, 1);
  assert.equal(items[0].url, "https://p.mt.gov.br/a/1");
});

// --- Transform / attribution ----------------------------------------------
test("toGhostPost always attributes the source + sets canonical", () => {
  const item = {
    title: "Obra entregue",
    url: "https://www.secom.mt.gov.br/noticias/obra-123",
    contentHtml: "<p>Corpo</p>",
    excerpt: "resumo",
    image: "https://x/img.jpg",
    date: new Date("2026-06-16T12:00:00Z"),
  };
  const src = { name: "SECOM-MT", attribution: "Governo de MT / SECOM-MT", tag: "Governo de MT" };
  const post = toGhostPost(item, src, { status: "draft", defaultTags: ["Notícias"] });
  assert.equal(post.canonical_url, item.url);
  assert.equal(post.status, "draft");
  assert.ok(post.html.includes("Fonte:"), "must include attribution text");
  assert.ok(post.html.includes(item.url), "must link to the source");
  assert.equal(post.feature_image, item.image);
  assert.deepEqual(post.tags.map((t) => t.name), ["Governo de MT", "Notícias"]);
});

// --- Dedupe ----------------------------------------------------------------
test("State remembers published urls across reloads", () => {
  const f = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "pub-")), "state.json");
  const s = new State(f);
  assert.equal(s.has("u1"), false);
  s.add("u1", { title: "t" });
  s.save();
  const s2 = new State(f);
  assert.equal(s2.has("u1"), true);
  assert.equal(s2.has("u2"), false);
});

console.log(`\n${passed} tests passed.`);
