// Dedupe store: remembers which source URLs were already published so re-runs
// never repost the same release. Plain JSON file, no dependencies.
import fs from "node:fs";
import path from "node:path";

export class State {
  constructor(file) {
    this.file = file;
    this.data = { published: {} };
    try {
      if (fs.existsSync(file)) {
        this.data = JSON.parse(fs.readFileSync(file, "utf8"));
        if (!this.data.published) this.data.published = {};
      }
    } catch {
      this.data = { published: {} };
    }
  }

  has(url) {
    return Boolean(this.data.published[url]);
  }

  add(url, meta = {}) {
    this.data.published[url] = { at: new Date().toISOString(), ...meta };
  }

  save() {
    fs.mkdirSync(path.dirname(this.file), { recursive: true });
    fs.writeFileSync(this.file, JSON.stringify(this.data, null, 2));
  }
}
