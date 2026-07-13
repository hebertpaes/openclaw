// Logging helpers — mirror the [openclaw] colored style used by the bash scripts.

const tty = process.stdout.isTTY;
const C = tty
  ? { blue: "\x1b[0;34m", green: "\x1b[0;32m", yellow: "\x1b[0;33m", red: "\x1b[0;31m", reset: "\x1b[0m" }
  : { blue: "", green: "", yellow: "", red: "", reset: "" };

const tag = (c) => `${c}[publisher]${C.reset}`;

export const log = {
  info: (...a) => console.log(tag(C.blue), ...a),
  ok: (...a) => console.log(tag(C.green), ...a),
  warn: (...a) => console.warn(tag(C.yellow), ...a),
  error: (...a) => console.error(tag(C.red), ...a),
};

export function die(msg, code = 1) {
  log.error(msg);
  process.exit(code);
}
