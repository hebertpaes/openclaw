// Ghost client — Admin API (create/publish posts) + Content API (read posts).
//
// Admin auth uses a short-lived JWT signed with the Admin API key
// ("{id}:{hex-secret}"), per https://ghost.org/docs/admin-api/#token-authentication
// No external dependencies — Node's built-in crypto signs the JWT.

import crypto from "node:crypto";
import { get, require_ } from "./config.js";

const ADMIN_API_VERSION = get("GHOST_API_VERSION", "v5.0");

function base64url(input) {
  return Buffer.from(input).toString("base64url");
}

// Build a Ghost Admin JWT valid for 5 minutes.
function adminToken() {
  const key = require_("GHOST_ADMIN_API_KEY");
  const [id, secret] = key.split(":");
  if (!id || !secret) throw new Error('GHOST_ADMIN_API_KEY must be "id:secret"');

  const header = base64url(JSON.stringify({ alg: "HS256", typ: "JWT", kid: id }));
  const iat = Math.floor(Date.now() / 1000);
  const payload = base64url(JSON.stringify({ iat, exp: iat + 300, aud: "/admin/" }));
  const data = `${header}.${payload}`;
  const sig = crypto
    .createHmac("sha256", Buffer.from(secret, "hex"))
    .update(data)
    .digest("base64url");
  return `${data}.${sig}`;
}

function baseUrl() {
  // GHOST_URL is the site root, e.g. https://odiapolitico.com.br
  return require_("GHOST_URL").replace(/\/+$/, "");
}

// Create (and optionally publish) a post. `post` accepts the Ghost post fields:
//   { title, html, status, tags, feature_image, excerpt, custom_excerpt, ... }
export async function createPost(post) {
  const url = `${baseUrl()}/ghost/api/admin/posts/?source=html`;
  const body = { posts: [{ status: "published", ...post }] };
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Ghost ${adminToken()}`,
      "Content-Type": "application/json",
      "Accept-Version": ADMIN_API_VERSION,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Ghost create failed (${res.status}): ${text}`);
  const data = JSON.parse(text);
  return data.posts[0];
}

// Fetch the most recent published post via the Content API.
// Requires GHOST_CONTENT_API_KEY (a read-only Content key).
export async function latestPost({ limit = 1 } = {}) {
  const key = require_("GHOST_CONTENT_API_KEY");
  const params = new URLSearchParams({
    key,
    limit: String(limit),
    include: "tags,authors",
    order: "published_at desc",
    formats: "html",
    filter: "status:published",
  });
  const url = `${baseUrl()}/ghost/api/content/posts/?${params}`;
  const res = await fetch(url, { headers: { "Accept-Version": ADMIN_API_VERSION } });
  const text = await res.text();
  if (!res.ok) throw new Error(`Ghost read failed (${res.status}): ${text}`);
  const data = JSON.parse(text);
  return limit === 1 ? data.posts[0] : data.posts;
}

// Fetch a single published post by id or slug via the Content API.
export async function getPost({ id, slug } = {}) {
  const key = require_("GHOST_CONTENT_API_KEY");
  const selector = id ? id : `slug/${slug}`;
  if (!id && !slug) throw new Error("getPost requires id or slug");
  const params = new URLSearchParams({ key, include: "tags,authors", formats: "html" });
  const url = `${baseUrl()}/ghost/api/content/posts/${selector}/?${params}`;
  const res = await fetch(url, { headers: { "Accept-Version": ADMIN_API_VERSION } });
  const text = await res.text();
  if (!res.ok) throw new Error(`Ghost read failed (${res.status}): ${text}`);
  return JSON.parse(text).posts[0];
}
