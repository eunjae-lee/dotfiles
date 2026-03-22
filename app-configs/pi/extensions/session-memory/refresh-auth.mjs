#!/usr/bin/env node
/**
 * OAuth Token Refresher
 *
 * Reads auth.json, checks if any OAuth tokens expire within 2 hours,
 * refreshes them if needed. Zero LLM cost — just HTTP token refresh.
 *
 * Usage: node refresh-auth.mjs
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const AUTH_PATH = join(homedir(), ".pi/agent/auth.json");
const REFRESH_THRESHOLD_MS = 2 * 60 * 60 * 1000; // 2 hours

// Import pi-ai OAuth refresh
const PI_AI_CANDIDATES = [
  "/opt/homebrew/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/@mariozechner/pi-ai/dist/oauth.js",
  "/usr/local/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/@mariozechner/pi-ai/dist/oauth.js",
];

let getOAuthApiKey;
for (const path of PI_AI_CANDIDATES) {
  if (existsSync(path)) {
    const oauth = await import(path);
    getOAuthApiKey = oauth.getOAuthApiKey;
    break;
  }
}

if (!getOAuthApiKey) {
  console.error("[auth-refresh] Could not import pi-ai OAuth module");
  process.exit(1);
}

if (!existsSync(AUTH_PATH)) {
  console.error("[auth-refresh] auth.json not found");
  process.exit(1);
}

const auth = JSON.parse(readFileSync(AUTH_PATH, "utf-8"));
let refreshed = false;

for (const [provider, creds] of Object.entries(auth)) {
  if (typeof creds !== "object" || creds.type !== "oauth") continue;

  const expiresMs = creds.expires || 0;
  const timeUntilExpiry = expiresMs - Date.now();

  if (timeUntilExpiry > REFRESH_THRESHOLD_MS) {
    console.log(`[auth-refresh] ${provider}: valid for ${Math.round(timeUntilExpiry / 3600000)}h — skip`);
    continue;
  }

  console.log(`[auth-refresh] ${provider}: expires in ${Math.round(timeUntilExpiry / 60000)}min — refreshing...`);

  try {
    const result = await getOAuthApiKey(provider, auth);
    if (result?.newCredentials) {
      auth[provider] = { type: "oauth", ...result.newCredentials };
      refreshed = true;
      console.log(`[auth-refresh] ${provider}: refreshed ✅ (new expiry: ${new Date(result.newCredentials.expires).toISOString()})`);
    } else {
      console.error(`[auth-refresh] ${provider}: refresh returned no credentials`);
    }
  } catch (err) {
    console.error(`[auth-refresh] ${provider}: refresh failed — ${err.message}`);
  }
}

if (refreshed) {
  writeFileSync(AUTH_PATH, JSON.stringify(auth, null, 2));
  console.log("[auth-refresh] auth.json updated");
} else {
  console.log("[auth-refresh] no refresh needed");
}
