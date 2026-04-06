#!/usr/bin/env node
/**
 * Session Memory v2 — Orchestrator
 *
 * Discovers targets via targetPaths globs, processes new sessions,
 * summarizes via LLM, writes to shared memory.
 *
 * Usage:
 *   node index.mjs              # Process new sessions
 *   node index.mjs --promote    # Run weekly promoter
 *   node index.mjs --dry-run    # Show what would be processed
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync, appendFileSync } from "node:fs";
import { join, resolve, dirname, relative, basename } from "node:path";
import { execFileSync, execSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── pi-ai import ──────────────────────────────────────────
// Resolve from global pi install
const PI_AI_PATH = findPiAi();

function findPiAi() {
  const candidates = [
    "/opt/homebrew/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/@mariozechner/pi-ai/dist/stream.js",
    "/usr/local/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/@mariozechner/pi-ai/dist/stream.js",
  ];
  for (const c of candidates) {
    if (existsSync(c)) return c;
  }
  return null;
}

const PI_AI_MODELS_PATH = PI_AI_PATH?.replace("stream.js", "models.js");
const PI_AI_OAUTH_PATH = PI_AI_PATH?.replace("stream.js", "oauth.js");
let completeSimple, getModel, getOAuthApiKey;

if (PI_AI_PATH) {
  const stream = await import(PI_AI_PATH);
  const models = await import(PI_AI_MODELS_PATH);
  const oauth = await import(PI_AI_OAUTH_PATH);
  completeSimple = stream.completeSimple;
  getModel = models.getModel;
  getOAuthApiKey = oauth.getOAuthApiKey;
}

// ── Config ────────────────────────────────────────────────

const CONFIG_PATH = join(homedir(), ".pi/agent/session-memory.json");
const STATE_DIR = join(homedir(), ".pi/agent/session-memory");
const INDEX_PATH = join(STATE_DIR, "index.json");

function expandHome(p) {
  if (!p) return p;
  return p.replace(/^~/, homedir());
}

function failConfig(message) {
  console.error(`CONFIG ERROR: ${message}`);
  process.exit(1);
}

function loadConfig() {
  if (!existsSync(CONFIG_PATH)) {
    failConfig(`Config not found: ${CONFIG_PATH}`);
  }

  const config = JSON.parse(readFileSync(CONFIG_PATH, "utf-8"));

  if (!config.memoryPath || typeof config.memoryPath !== "string") {
    failConfig(`session-memory.json is missing required string field \"memoryPath\"`);
  }
  if (!Array.isArray(config.targetPaths) || config.targetPaths.length === 0) {
    failConfig(`session-memory.json must define a non-empty \"targetPaths\" array`);
  }

  return config;
}

function loadIndex() {
  if (!existsSync(INDEX_PATH)) return {};
  try {
    return JSON.parse(readFileSync(INDEX_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function saveIndex(index) {
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(INDEX_PATH, JSON.stringify(index, null, 2) + "\n");
}

// ── Target Discovery ──────────────────────────────────────

function discoverTargets(config) {
  const targets = [];

  for (const pattern of config.targetPaths) {
    const expanded = expandHome(pattern);

    // Handle glob: only supports trailing /*
    if (expanded.endsWith("/*")) {
      const baseDir = expanded.slice(0, -2);
      if (!existsSync(baseDir)) continue;
      for (const entry of readdirSync(baseDir)) {
        const dir = join(baseDir, entry);
        const memJson = join(dir, "memory.json");
        if (existsSync(memJson)) {
          targets.push(loadTarget(memJson));
        }
      }
    } else {
      const memJson = join(expanded, "memory.json");
      if (existsSync(memJson)) {
        targets.push(loadTarget(memJson));
      }
    }
  }

  return targets;
}

function loadTarget(memJsonPath) {
  const config = JSON.parse(readFileSync(memJsonPath, "utf-8"));
  const baseDir = dirname(memJsonPath);
  const inferredSlug = baseDir === join(homedir(), ".pi/agent") ? "host" : basename(baseDir);

  if (!config.sessionsPath || typeof config.sessionsPath !== "string") {
    failConfig(`${relative(homedir(), memJsonPath)} is missing required string field \"sessionsPath\"`);
  }

  const slug = config.slug || inferredSlug;
  if (!slug || typeof slug !== "string") {
    failConfig(`${relative(homedir(), memJsonPath)} is missing required string field \"slug\" and it could not be inferred`);
  }

  const sessionsPath = resolve(baseDir, config.sessionsPath);
  return {
    slug,
    sessionsPath,
    memoryPath: config.memoryPath ? expandHome(config.memoryPath) : null,
    model: config.model || "anthropic/claude-sonnet-4-0",
    memJsonPath,
  };
}

// ── Session Discovery ─────────────────────────────────────

function validateTargets(config, targets) {
  const seen = new Map();
  const rootMemoryPath = expandHome(config.memoryPath);

  if (!existsSync(rootMemoryPath)) {
    failConfig(`memoryPath does not exist: ${rootMemoryPath}`);
  }

  if (targets.length === 0) {
    failConfig(`No targets discovered from targetPaths in ${CONFIG_PATH}`);
  }

  for (const target of targets) {
    if (seen.has(target.slug)) {
      failConfig(`Duplicate target slug \"${target.slug}\" in ${relative(homedir(), seen.get(target.slug))} and ${relative(homedir(), target.memJsonPath)}`);
    }
    seen.set(target.slug, target.memJsonPath);

    if (!target.model.includes('/')) {
      failConfig(`${relative(homedir(), target.memJsonPath)} has invalid model \"${target.model}\"; expected provider/model`);
    }

    const effectiveMemoryPath = target.memoryPath || join(rootMemoryPath, target.slug);
    if (!effectiveMemoryPath) {
      failConfig(`${relative(homedir(), target.memJsonPath)} could not determine memory path`);
    }
  }
}

function findSessionFiles(sessionsPath) {
  if (!existsSync(sessionsPath)) return [];
  const files = [];

  function walk(dir, prefix) {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      const rel = prefix ? `${prefix}/${entry}` : entry;
      const stat = statSync(full);
      if (stat.isDirectory()) {
        walk(full, rel);
      } else if (entry.endsWith(".jsonl")) {
        files.push({ path: full, key: `${rel}`, mtime: stat.mtimeMs });
      }
    }
  }

  walk(sessionsPath, "");
  return files;
}

// ── API Key ───────────────────────────────────────────────

async function getApiKey(provider) {
  // Check env var first
  const envKey = `${provider.toUpperCase()}_API_KEY`;
  if (process.env[envKey]) return process.env[envKey];

  // Try auth.json with OAuth refresh
  const authPath = join(homedir(), ".pi/agent/auth.json");
  if (existsSync(authPath) && getOAuthApiKey) {
    try {
      const auth = JSON.parse(readFileSync(authPath, "utf-8"));

      // Direct API key
      if (auth[provider]?.apiKey) return auth[provider].apiKey;

      // OAuth — use pi-ai's refresh logic
      if (auth[provider]?.type === "oauth") {
        const result = await getOAuthApiKey(provider, auth);
        if (result) {
          // Save refreshed credentials back to auth.json
          if (result.newCredentials) {
            const updated = { ...auth, [provider]: { type: "oauth", ...result.newCredentials } };
            writeFileSync(authPath, JSON.stringify(updated, null, 2));
            console.log(`  Refreshed OAuth token for ${provider}`);
          }
          return result.apiKey;
        }
      }

      // Fallback: raw access token
      if (auth[provider]?.access) return auth[provider].access;
    } catch (err) {
      console.error(`  Auth error for ${provider}: ${err.message}`);
    }
  }

  return null;
}

// ── LLM Summarization ─────────────────────────────────────

async function summarizeSession(preprocessed, target, apiKey) {
  const [provider, modelId] = target.model.split("/");
  const model = getModel(provider, modelId);

  if (!model) {
    console.error(`  Model not found: ${target.model}`);
    return null;
  }

  let prompt = `# Session Summary Request\n\n`;
  prompt += `Source: ${target.slug} bot\n`;
  prompt += `Session: ${preprocessed.sessionId}\n`;
  prompt += `Date: ${preprocessed.startTime?.split("T")[0] || "unknown"}\n\n`;

  if (preprocessed.compactionSummary) {
    prompt += `## Prior Context (compacted)\n\n${preprocessed.compactionSummary}\n\n`;
  }

  prompt += `## Conversation\n\n`;
  for (const msg of preprocessed.conversation.slice(-100)) {
    // Limit to last 100 messages to stay within context
    prompt += `**${msg.role}**: ${msg.text}\n\n`;
  }

  prompt += `## Instructions\n\n`;
  prompt += `Summarize this session. Focus on:\n`;
  prompt += `- What was the user trying to accomplish?\n`;
  prompt += `- What decisions were made and why?\n`;
  prompt += `- What preferences or corrections did the user express?\n`;
  prompt += `- What was the outcome?\n`;
  prompt += `- Any important context for future sessions?\n\n`;
  prompt += `If the session is trivial (just greetings, quick lookups, etc.), respond with just "SKIP".\n\n`;
  prompt += `Otherwise, write a concise summary (1-3 paragraphs). Use markdown. Start with a bold one-line title.`;

  try {
    const response = await completeSimple(model, {
      messages: [{ role: "user", content: prompt }],
    }, { apiKey, maxTokens: 1000 });

    if (response.stopReason === "error") {
      console.error(`  LLM error: ${response.errorMessage || "unknown"}`);
      return null;
    }

    const text = response.content
      .filter((c) => c.type === "text")
      .map((c) => c.text)
      .join("")
      .trim();

    return text;
  } catch (err) {
    console.error(`  LLM call failed: ${err.message}`);
    return null;
  }
}

function pruneShortTermFile(shortTermPath, shortTermConfig = {}) {
  if (!existsSync(shortTermPath)) return;

  const maxSummaries = Number.isFinite(shortTermConfig.maxSummaries) ? shortTermConfig.maxSummaries : null;
  const retentionDays = Number.isFinite(shortTermConfig.retentionDays) ? shortTermConfig.retentionDays : null;
  if (!maxSummaries && !retentionDays) return;

  const content = readFileSync(shortTermPath, "utf-8");
  const header = "# Short-Term Memory\n";
  const body = content.startsWith(header) ? content.slice(header.length) : content;
  const rawSections = body.split(/\n(?=### )/).map((s) => s.trim()).filter(Boolean);

  let entries = rawSections.map((section) => {
    const heading = section.split("\n", 1)[0] || "";
    const m = heading.match(/\((\d{4}-\d{2}-\d{2})\)$/);
    const date = m ? new Date(`${m[1]}T00:00:00Z`) : null;
    return { section, date };
  });

  if (retentionDays) {
    const cutoff = new Date();
    cutoff.setUTCDate(cutoff.getUTCDate() - retentionDays);
    entries = entries.filter((entry) => !entry.date || entry.date >= cutoff);
  }

  if (maxSummaries && entries.length > maxSummaries) {
    entries = entries.slice(-maxSummaries);
  }

  const pruned = header + (entries.length ? `\n${entries.map((e) => e.section).join("\n\n")}`.trimEnd() + "\n" : "");
  writeFileSync(shortTermPath, pruned);
}

// ── Main ──────────────────────────────────────────────────

const dryRun = process.argv.includes("--dry-run");
const promote = process.argv.includes("--promote");

const config = loadConfig();
const memoryPath = expandHome(config.memoryPath);

if (promote) {
  await runPromoter(config);
  process.exit(0);
}

if (!completeSimple || !getModel) {
  console.error("Could not import pi-ai. Is pi installed globally?");
  process.exit(1);
}

const targets = discoverTargets(config);
validateTargets(config, targets);
console.log(`Discovered ${targets.length} targets: ${targets.map((t) => t.slug).join(", ")}`);

const index = loadIndex();
let totalProcessed = 0;
let totalSkipped = 0;

for (const target of targets) {
  console.log(`\nProcessing: ${target.slug} (${target.sessionsPath})`);

  const sessionFiles = findSessionFiles(target.sessionsPath);
  console.log(`  Found ${sessionFiles.length} session files`);

  const apiKey = await getApiKey(target.model.split("/")[0]);
  if (!apiKey) {
    console.error(`  No API key for ${target.model.split("/")[0]} — skipping`);
    continue;
  }

  for (const file of sessionFiles) {
    const indexKey = `${target.slug}:${file.key}`;
    const lastProcessed = index[indexKey]?.lastTimestamp;

    // Check if file was modified after last processing
    if (lastProcessed) {
      const lastMs = new Date(lastProcessed).getTime();
      if (file.mtime <= lastMs) {
        continue; // Already processed and not modified
      }
    }

    console.log(`  Processing: ${file.key}`);

    if (dryRun) {
      console.log(`    [dry-run] Would process`);
      totalProcessed++;
      continue;
    }

    // Preprocess
    let preprocessed;
    try {
      const output = execFileSync("node", [
        join(__dirname, "preprocess.mjs"),
        file.path,
        ...(lastProcessed ? ["--after", lastProcessed] : []),
      ], { encoding: "utf-8", timeout: 30000 });
      preprocessed = JSON.parse(output);
    } catch (err) {
      console.error(`    Preprocess failed: ${err.message}`);
      continue;
    }

    if (preprocessed.conversation.length === 0 && !preprocessed.compactionSummary) {
      console.log(`    No new content — skipping`);
      index[indexKey] = { lastTimestamp: new Date().toISOString() };
      continue;
    }

    console.log(`    ${preprocessed.conversation.length} messages, compaction: ${preprocessed.compactionSummary ? "yes" : "no"}`);

    // Summarize
    const summary = await summarizeSession(preprocessed, target, apiKey);

    if (!summary) {
      console.error(`    Summarization failed`);
      continue;
    }

    if (summary.trim().toUpperCase() === "SKIP") {
      console.log(`    SKIP — trivial session`);
      totalSkipped++;
    } else {
      // Write to short-term.md
      const slugMemDir = target.memoryPath || join(memoryPath, target.slug);
      mkdirSync(slugMemDir, { recursive: true });
      const shortTermPath = join(slugMemDir, "short-term.md");

      // Ensure file has header
      if (!existsSync(shortTermPath)) {
        writeFileSync(shortTermPath, "# Short-Term Memory\n");
      }

      const date = preprocessed.startTime?.split("T")[0] || new Date().toISOString().split("T")[0];
      const entry = `\n### ${target.slug} / ${preprocessed.sessionId} (${date})\n\n${summary}\n\n---\n`;
      appendFileSync(shortTermPath, entry);
      pruneShortTermFile(shortTermPath, config.shortTerm);

      console.log(`    ✅ Written to ${target.slug}/short-term.md`);
      totalProcessed++;
    }

    // Update index
    index[indexKey] = { lastTimestamp: new Date().toISOString() };
    saveIndex(index);
  }
}

console.log(`\nDone: ${totalProcessed} processed, ${totalSkipped} skipped`);

// Auto-commit
if (config.autoCommit && totalProcessed > 0 && !dryRun) {
  try {
    console.log("Auto-committing...");
    execSync(`cd "${memoryPath}" && git add -A && git commit -m "session-memory: auto-summarize" && git push`, {
      encoding: "utf-8",
      timeout: 30000,
      stdio: "pipe",
    });
    console.log("Committed and pushed.");
  } catch (err) {
    // May fail if nothing to commit
    if (!err.message?.includes("nothing to commit")) {
      console.error(`Auto-commit failed: ${err.message?.slice(0, 200)}`);
    }
  }
}

// ── Promoter ──────────────────────────────────────────────

async function runPromoter(config) {
  console.log("Running memory promoter...");

  const apiKey = await getApiKey("anthropic");
  if (!apiKey) {
    console.error("No API key for promoter");
    return;
  }

  const model = getModel("anthropic", "claude-sonnet-4-0");
  if (!model) {
    console.error("Model not found: anthropic/claude-sonnet-4-0");
    return;
  }

  const memPath = expandHome(config.memoryPath);
  const targets = discoverTargets(config);
  let updated = 0;

  for (const target of targets) {
    const targetMemDir = target.memoryPath || join(memPath, target.slug);
    const stPath = join(targetMemDir, "short-term.md");
    if (!existsSync(stPath)) {
      console.log(`  ${target.slug}: no short-term.md — skipping`);
      continue;
    }

    const shortTerm = readFileSync(stPath, "utf-8").trim();
    if (!shortTerm) {
      console.log(`  ${target.slug}: empty short-term.md — skipping`);
      continue;
    }

    const ltPath = join(targetMemDir, "long-term.md");
    const existingLongTerm = existsSync(ltPath) ? readFileSync(ltPath, "utf-8") : "";

    let prompt = `# Memory Promotion\n\n`;
    prompt += `Target: ${target.slug}\n\n`;
    prompt += `## Current Long-Term Memory\n\n${existingLongTerm || "(empty)"}\n\n`;
    prompt += `## Recent Short-Term Memories\n\n${shortTerm}\n\n`;
    prompt += `## Instructions\n\n`;
    prompt += `Review the short-term memories and update the long-term memory for this target only.\n`;
    prompt += `- Identify recurring patterns, confirmed preferences, and important decisions\n`;
    prompt += `- Merge with existing long-term entries — deduplicate and supersede outdated entries\n`;
    prompt += `- Remove anything no longer relevant\n`;
    prompt += `- Keep it organized by category (User Preferences, Architecture Decisions, Project Knowledge, Patterns & Corrections)\n`;
    prompt += `- Output the complete updated long-term memory in markdown\n`;

    try {
      const response = await completeSimple(model, {
        messages: [{ role: "user", content: prompt }],
      }, { apiKey, maxTokens: 4000 });

      if (response.stopReason === "error") {
        console.error(`  ${target.slug}: promoter LLM error: ${response.errorMessage}`);
        continue;
      }

      const text = response.content
        .filter((c) => c.type === "text")
        .map((c) => c.text)
        .join("")
        .trim();

      mkdirSync(targetMemDir, { recursive: true });
      writeFileSync(ltPath, text + "\n");
      console.log(`  ✅ ${target.slug}: updated ${ltPath}`);
      updated++;
    } catch (err) {
      console.error(`  ${target.slug}: promoter failed: ${err.message}`);
    }
  }

  if (config.autoCommit && updated > 0) {
    try {
      execSync(`cd "${memPath}" && git add -A && git commit -m "session-memory: promote to long-term" && git push`, {
        encoding: "utf-8",
        timeout: 30000,
        stdio: "pipe",
      });
      console.log("Committed and pushed.");
    } catch {}
  }
}
