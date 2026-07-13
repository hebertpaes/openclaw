// X (Twitter) adapter — posts a tweet via API v2 using OAuth 1.0a user context.
// Requires an app + access token with write permission:
//   X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_SECRET
// Docs: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets

import crypto from "node:crypto";
import { get, has } from "../config.js";

export const name = "x";

export function configured() {
  return has("X_API_KEY", "X_API_SECRET", "X_ACCESS_TOKEN", "X_ACCESS_SECRET");
}

const enc = (s) => encodeURIComponent(s).replace(/[!*'()]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase());

function oauthHeader(method, url) {
  const params = {
    oauth_consumer_key: get("X_API_KEY"),
    oauth_nonce: crypto.randomBytes(16).toString("hex"),
    oauth_signature_method: "HMAC-SHA1",
    oauth_timestamp: String(Math.floor(Date.now() / 1000)),
    oauth_token: get("X_ACCESS_TOKEN"),
    oauth_version: "1.0",
  };
  // JSON body params are NOT part of the OAuth 1.0a signature base string.
  const paramString = Object.keys(params)
    .sort()
    .map((k) => `${enc(k)}=${enc(params[k])}`)
    .join("&");
  const base = `${method.toUpperCase()}&${enc(url)}&${enc(paramString)}`;
  const signingKey = `${enc(get("X_API_SECRET"))}&${enc(get("X_ACCESS_SECRET"))}`;
  const signature = crypto.createHmac("sha1", signingKey).update(base).digest("base64");
  const header = { ...params, oauth_signature: signature };
  return (
    "OAuth " +
    Object.keys(header)
      .sort()
      .map((k) => `${enc(k)}="${enc(header[k])}"`)
      .join(", ")
  );
}

export async function post(msg, { dryRun } = {}) {
  const text = msg.x;
  const url = "https://api.twitter.com/2/tweets";
  if (dryRun) return { dryRun: true, text };
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: oauthHeader("POST", url),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ text }),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`X post failed (${res.status}): ${body}`);
  const data = JSON.parse(body);
  return { id: data.data?.id };
}
