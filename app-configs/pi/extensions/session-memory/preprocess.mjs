#!/usr/bin/env node
/**
 * Session Memory Pre-processor
 *
 * Parses pi session JSONL files and extracts clean conversation data
 * for LLM summarization. Compaction-aware: uses pi's own compaction
 * summaries when available, only sends the "tail" to the LLM.
 *
 * Usage:
 *   node session-memory-preprocess.mjs <source-path> <source-name>
 *
 * Reads index.json from ~/.pi/agent/session-memory/ for progress tracking.
 * Outputs JSON to stdout with the sessions that need processing.
 */

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, basename } from "node:path";

function expandHome(p) {
  return p.replace(/^~/, process.env.HOME || "/root");
}

const INDEX_PATH = join(expandHome("~/.pi/agent/session-memory"), "index.json");

function loadIndex() {
  if (!existsSync(INDEX_PATH)) return {};
  try {
    return JSON.parse(readFileSync(INDEX_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function findJsonlFiles(dir) {
  const files = [];
  if (!existsSync(dir)) return files;

  function walk(d) {
    for (const entry of readdirSync(d, { withFileTypes: true })) {
      const full = join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith(".jsonl")) files.push(full);
    }
  }
  walk(dir);
  return files.sort();
}

function parseJsonlFile(filePath, afterTimestamp) {
  const content = readFileSync(filePath, "utf-8");
  const lines = content.trim().split("\n");

  let sessionMeta = null;
  let lastCompaction = null;
  let lastCompactionIndex = -1;
  const allEntries = [];

  for (let i = 0; i < lines.length; i++) {
    let entry;
    try {
      entry = JSON.parse(lines[i]);
    } catch {
      continue;
    }
    allEntries.push({ index: i, entry });

    if (entry.type === "session") {
      sessionMeta = entry;
    } else if (entry.type === "compaction") {
      lastCompaction = entry;
      lastCompactionIndex = i;
    }
  }

  // Filter entries after the last-processed timestamp
  const cutoffTimestamp = afterTimestamp || null;

  // Build the output
  const result = {
    file: filePath,
    sessionId: sessionMeta?.id || basename(filePath, ".jsonl"),
    sessionTimestamp: sessionMeta?.timestamp || null,
    cwd: sessionMeta?.cwd || null,
    compactionSummary: null,
    conversation: [],
    latestTimestamp: null,
  };

  // Determine where to start processing
  let startIndex = 0;

  if (lastCompaction) {
    // If the compaction is newer than our last processed timestamp,
    // include it as context
    if (!cutoffTimestamp || lastCompaction.timestamp > cutoffTimestamp) {
      result.compactionSummary = lastCompaction.summary;
    }
    // Start processing from after the last compaction
    startIndex = lastCompactionIndex + 1;
  }

  for (const { entry } of allEntries.slice(startIndex)) {
    // Skip entries we've already processed
    if (cutoffTimestamp && entry.timestamp && entry.timestamp <= cutoffTimestamp) {
      continue;
    }

    if (entry.type !== "message") continue;

    const msg = entry.message;
    if (!msg) continue;

    if (msg.role === "user") {
      const textParts = (msg.content || [])
        .filter((c) => c.type === "text")
        .map((c) => c.text);
      if (textParts.length > 0) {
        result.conversation.push({
          role: "user",
          text: textParts.join("\n"),
          timestamp: entry.timestamp,
        });
      }
    } else if (msg.role === "assistant") {
      // Only text blocks — skip thinking, toolCall, usage
      const textParts = (msg.content || [])
        .filter((c) => c.type === "text")
        .map((c) => c.text);
      if (textParts.length > 0) {
        result.conversation.push({
          role: "assistant",
          text: textParts.join("\n"),
          timestamp: entry.timestamp,
        });
      }
    }
    // Skip toolResult, model_change, thinking_level_change, etc.

    // Track latest timestamp
    if (entry.timestamp) {
      if (!result.latestTimestamp || entry.timestamp > result.latestTimestamp) {
        result.latestTimestamp = entry.timestamp;
      }
    }
  }

  return result;
}

// --- Main ---

const [, , sourcePath, sourceName] = process.argv;

if (!sourcePath || !sourceName) {
  console.error(
    "Usage: node session-memory-preprocess.mjs <source-path> <source-name>"
  );
  process.exit(1);
}

const resolvedSourcePath = expandHome(sourcePath);

const index = loadIndex();
const jsonlFiles = findJsonlFiles(resolvedSourcePath);

const sessions = [];

for (const file of jsonlFiles) {
  const fileKey = `${sourceName}:${basename(file)}`;
  const lastTimestamp = index[fileKey]?.lastTimestamp || null;

  const parsed = parseJsonlFile(file, lastTimestamp);

  // Only include if there's something new
  const hasNewContent =
    parsed.conversation.length > 0 ||
    (parsed.compactionSummary && !lastTimestamp);

  if (hasNewContent) {
    sessions.push({
      ...parsed,
      sourceName,
      fileKey,
    });
  }
}

// Output to stdout
console.log(JSON.stringify({ sessions, sourceName }, null, 2));
