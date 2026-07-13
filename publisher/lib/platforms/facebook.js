// Facebook Page adapter — publishes a link post to a Page feed via the Graph API.
//   FB_PAGE_ID, FB_PAGE_ACCESS_TOKEN  (long-lived Page token with pages_manage_posts)
// Docs: https://developers.facebook.com/docs/pages-api/posts

import { get, has } from "../config.js";

export const name = "facebook";

const GRAPH = get("GRAPH_API_VERSION", "v21.0");

export function configured() {
  return has("FB_PAGE_ID", "FB_PAGE_ACCESS_TOKEN");
}

export async function post(msg, { dryRun } = {}) {
  const pageId = get("FB_PAGE_ID");
  const url = `https://graph.facebook.com/${GRAPH}/${pageId}/feed`;
  const params = new URLSearchParams({
    message: msg.facebook,
    access_token: get("FB_PAGE_ACCESS_TOKEN"),
  });
  if (msg.url) params.set("link", msg.url);
  if (dryRun) return { dryRun: true, message: msg.facebook, link: msg.url };
  const res = await fetch(url, { method: "POST", body: params });
  const body = await res.text();
  if (!res.ok) throw new Error(`Facebook post failed (${res.status}): ${body}`);
  return { id: JSON.parse(body).id };
}
