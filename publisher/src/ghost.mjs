// Zero-dependency Ghost Admin API client.
// Builds the Admin API JWT with Node's crypto and posts via global fetch.
import crypto from "node:crypto";

function base64url(input) {
  return Buffer.from(input).toString("base64url");
}

/**
 * Build a short-lived Admin API JWT from a key formatted "id:secret" (secret is hex).
 * See https://ghost.org/docs/admin-api/#token-authentication
 */
export function makeToken(adminApiKey, nowSeconds = Math.floor(Date.now() / 1000)) {
  const [id, secret] = String(adminApiKey).split(":");
  if (!id || !secret) throw new Error('GHOST_ADMIN_API_KEY must look like "id:secret".');

  const header = { alg: "HS256", typ: "JWT", kid: id };
  const payload = { iat: nowSeconds, exp: nowSeconds + 5 * 60, aud: "/admin/" };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const signature = crypto
    .createHmac("sha256", Buffer.from(secret, "hex"))
    .update(unsigned)
    .digest("base64url");
  return `${unsigned}.${signature}`;
}

export class GhostClient {
  /**
   * @param {object} o
   * @param {string} o.apiUrl   Base site URL, e.g. https://odiapolitico.com.br
   * @param {string} o.adminApiKey  "id:secret"
   * @param {string} [o.version]    Ghost Accept-Version (default v5.0)
   * @param {boolean} [o.dryRun]    If true, never POST — just return the payload.
   */
  constructor({ apiUrl, adminApiKey, version = "v5.0", dryRun = false }) {
    if (!apiUrl) throw new Error("GHOST_ADMIN_API_URL is required.");
    this.apiUrl = apiUrl.replace(/\/+$/, "");
    this.adminApiKey = adminApiKey;
    this.version = version;
    this.dryRun = dryRun;
  }

  /**
   * Create a post. `post` is a Ghost post object (title, html, status, tags, ...).
   * With ?source=html Ghost converts the `html` field to its internal format.
   */
  async createPost(post) {
    const endpoint = `${this.apiUrl}/ghost/api/admin/posts/?source=html`;
    const body = JSON.stringify({ posts: [post] });

    if (this.dryRun) {
      return { dryRun: true, endpoint, post };
    }
    if (!this.adminApiKey) throw new Error("GHOST_ADMIN_API_KEY is required to publish.");

    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Ghost ${makeToken(this.adminApiKey)}`,
        "Content-Type": "application/json",
        "Accept-Version": this.version,
      },
      body,
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`Ghost API ${res.status}: ${text.slice(0, 500)}`);
    }
    const json = text ? JSON.parse(text) : {};
    return json.posts ? json.posts[0] : json;
  }
}
