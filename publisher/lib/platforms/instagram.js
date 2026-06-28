// Instagram adapter — publishes a single image post via the Graph API.
// Two steps: create a media container, then publish it. Requires a public
// image URL (the post's feature image).
//   IG_USER_ID, IG_ACCESS_TOKEN  (IG Business account linked to a FB Page)
// Docs: https://developers.facebook.com/docs/instagram-api/guides/content-publishing

import { get, has } from "../config.js";

export const name = "instagram";

const GRAPH = get("GRAPH_API_VERSION", "v21.0");

export function configured() {
  return has("IG_USER_ID", "IG_ACCESS_TOKEN");
}

export async function post(msg, { dryRun } = {}) {
  if (!msg.image) {
    return { skipped: true, reason: "Instagram requer uma imagem (feature_image do post)." };
  }
  const igId = get("IG_USER_ID");
  const token = get("IG_ACCESS_TOKEN");
  if (dryRun) return { dryRun: true, caption: msg.instagram, image: msg.image };

  // 1) Create container.
  const createUrl = `https://graph.facebook.com/${GRAPH}/${igId}/media`;
  const createParams = new URLSearchParams({
    image_url: msg.image,
    caption: msg.instagram,
    access_token: token,
  });
  let res = await fetch(createUrl, { method: "POST", body: createParams });
  let body = await res.text();
  if (!res.ok) throw new Error(`Instagram container failed (${res.status}): ${body}`);
  const creationId = JSON.parse(body).id;

  // 2) Publish container.
  const pubUrl = `https://graph.facebook.com/${GRAPH}/${igId}/media_publish`;
  const pubParams = new URLSearchParams({ creation_id: creationId, access_token: token });
  res = await fetch(pubUrl, { method: "POST", body: pubParams });
  body = await res.text();
  if (!res.ok) throw new Error(`Instagram publish failed (${res.status}): ${body}`);
  return { id: JSON.parse(body).id };
}
