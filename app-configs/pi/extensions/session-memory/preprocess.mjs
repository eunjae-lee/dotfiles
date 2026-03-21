#!/usr/bin/env node
/**
 * Session JSONL Preprocessor
 *
 * Parses a pi session JSONL file and extracts clean conversation text
 * suitable for LLM summarization.
 *
 * Handles compaction: discards entries before the last compaction entry
 * and uses the compaction's summary as prior context.
 *
 * Usage: node preprocess.mjs <session.jsonl> [--after <ISO-timestamp>]
 * Output: JSON to stdout { compactionSummary, conversation, sessionId, startTime }
 */

import { readFileSync } from "node:fs";

const args = process.argv.slice(2);
const filePath = args[0];
const afterIdx = args.indexOf("--after");
const afterTimestamp = afterIdx !== -1 ? args[afterIdx + 1] : null;

if (!filePath) {
  console.error("Usage: node preprocess.mjs <session.jsonl> [--after <ISO-timestamp>]");
  process.exit(1);
}

const lines = readFileSync(filePath, "utf-8").split("\n").filter((l) => l.trim());
const entries = lines.map((l) => JSON.parse(l));

// Find session metadata
const sessionEntry = entries.find((e) => e.type === "session");
const sessionId = sessionEntry?.id || "unknown";

// Find the last compaction
let lastCompactionIdx = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  if (entries[i].type === "compaction") {
    lastCompactionIdx = i;
    break;
  }
}

const compactionSummary =
  lastCompactionIdx >= 0 ? entries[lastCompactionIdx].summary || "" : "";

// Process entries after the last compaction (or all if no compaction)
const startIdx = lastCompactionIdx >= 0 ? lastCompactionIdx + 1 : 0;
const conversation = [];
let startTime = null;

for (let i = startIdx; i < entries.length; i++) {
  const entry = entries[i];

  // Skip non-message entries
  if (entry.type !== "message") continue;

  const msg = entry.message;
  if (!msg) continue;

  const timestamp = entry.timestamp || msg.timestamp;

  // Apply --after filter
  if (afterTimestamp && timestamp && timestamp <= afterTimestamp) continue;

  // Track start time
  if (!startTime && timestamp) startTime = timestamp;

  const role = msg.role;
  const content = msg.content;

  if (role === "user") {
    // Extract text from user messages
    if (typeof content === "string") {
      conversation.push({ role: "user", text: content });
    } else if (Array.isArray(content)) {
      const text = content
        .filter((c) => c.type === "text")
        .map((c) => c.text)
        .join("\n");
      if (text) conversation.push({ role: "user", text });
    }
  } else if (role === "assistant") {
    // Extract only text blocks from assistant (skip thinking, toolCall, usage)
    if (Array.isArray(content)) {
      const text = content
        .filter((c) => c.type === "text")
        .map((c) => c.text)
        .join("\n");
      if (text) conversation.push({ role: "assistant", text });
    }
  }
  // Skip: toolResult, model_change, thinking_level_change, etc.
}

const result = {
  sessionId: sessionId.slice(0, 6),
  startTime: startTime || sessionEntry?.timestamp || null,
  compactionSummary,
  conversation,
};

console.log(JSON.stringify(result));
