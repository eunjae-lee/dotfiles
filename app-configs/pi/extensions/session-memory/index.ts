import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { execSync } from "node:child_process";

function expandHome(p: string): string {
  return p.replace(/^~/, process.env.HOME || "/root");
}

interface Source {
  name: string;
  path: string;
  schedule: string;
  weight: number;
}

interface Config {
  memoryPath: string;
  model: string;
  shortTerm: { maxSummaries: number; retentionDays: number };
  sources: Source[];
  promoter: { schedule: string };
  autoCommit: boolean;
}

function loadConfig(): Config | null {
  const configPath = expandHome("~/.pi/agent/session-memory.json");
  if (!existsSync(configPath)) return null;
  try {
    const raw = JSON.parse(readFileSync(configPath, "utf-8"));
    return {
      memoryPath: expandHome(raw.memoryPath),
      model: raw.model || "anthropic/claude-sonnet-4",
      shortTerm: {
        maxSummaries: raw.shortTerm?.maxSummaries ?? 10,
        retentionDays: raw.shortTerm?.retentionDays ?? 14,
      },
      sources: (raw.sources || []).map((s: any) => {
        const resolvedPath = expandHome(s.path);
        const inferredName = resolvedPath.split("/").filter(Boolean).pop() || "unknown";
        return {
          name: s.name || inferredName,
          path: resolvedPath,
          schedule: s.schedule,
          weight: s.weight ?? 1.0,
        };
      }),
      promoter: { schedule: raw.promoter?.schedule || "0 0 0 * * 0" },
      autoCommit: raw.autoCommit ?? true,
    };
  } catch (e) {
    console.error("[session-memory] Failed to load config:", e);
    return null;
  }
}

const INDEX_DIR = expandHome("~/.pi/agent/session-memory");
const INDEX_PATH = join(INDEX_DIR, "index.json");

function loadIndex(): Record<string, { lastTimestamp: string }> {
  if (!existsSync(INDEX_PATH)) return {};
  try {
    return JSON.parse(readFileSync(INDEX_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function saveIndex(index: Record<string, { lastTimestamp: string }>) {
  if (!existsSync(INDEX_DIR)) mkdirSync(INDEX_DIR, { recursive: true });
  writeFileSync(INDEX_PATH, JSON.stringify(index, null, 2) + "\n");
}

function ensureDirs(memoryPath: string) {
  for (const dir of [
    join(memoryPath, "archive"),
    join(INDEX_DIR, "sessions"),
  ]) {
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  }
}

function gitCommitAndPush(memoryPath: string, message: string) {
  try {
    execSync(`git add -A && git commit -m "${message}" && git push`, {
      cwd: memoryPath,
      stdio: "pipe",
      timeout: 30_000,
    });
  } catch {
    // May fail if nothing to commit
  }
}

function buildSummarizationPrompt(
  session: any,
  weight: number,
): string {
  let prompt = "";

  if (session.compactionSummary) {
    prompt += `## Prior context (pi's own session summary)\n\n${session.compactionSummary}\n\n`;
  }

  if (session.conversation.length > 0) {
    prompt += `## Recent conversation\n\n`;
    for (const msg of session.conversation) {
      const role = msg.role === "user" ? "User" : "Assistant";
      prompt += `**${role}** (${msg.timestamp}):\n${msg.text}\n\n`;
    }
  }

  prompt += `---\n\n`;
  prompt += `Summarize this coding session. Focus on:\n`;
  prompt += `- What was the user trying to accomplish?\n`;
  prompt += `- What decisions were made and why?\n`;
  prompt += `- What preferences or corrections did the user express?\n`;
  prompt += `- What was the outcome?\n`;
  prompt += `- Any important context for future sessions?\n\n`;
  prompt += `Importance threshold: ${weight} (0–1 scale).\n`;
  prompt += `- At 1.0: save anything worth remembering.\n`;
  prompt += `- At 0.5: only save moderately important or above — skip routine, low-value sessions.\n`;
  prompt += `- At 0.1: only save highly significant sessions — major decisions, user corrections, critical knowledge.\n\n`;
  prompt += `If the session doesn't meet the threshold, respond with exactly "SKIP" and nothing else.\n`;
  prompt += `Otherwise, write a concise markdown summary (no heading, just content).`;

  return prompt;
}

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  if (!config) return; // No config = extension disabled

  const scriptPath = join(dirname(new URL(import.meta.url).pathname), "preprocess.mjs");
  const log = (msg: string) => console.error(`[session-memory] ${msg}`);

  log(`Loaded config: ${config.sources.length} sources, memoryPath=${config.memoryPath}`);
  ensureDirs(config.memoryPath);

  // Register the summarize tool (called by scheduled prompts)
  pi.registerTool({
    name: "session_memory_summarize",
    label: "Session Memory Summarize",
    description:
      "Process new session data from a configured source and generate summaries. Called by scheduled jobs.",
    parameters: {
      type: "object" as const,
      properties: {
        sourceName: {
          type: "string" as const,
          description: "Name of the source to process (from config)",
        },
      },
      required: ["sourceName"],
    },
    async execute(_toolCallId, params: { sourceName: string }, _signal, _onUpdate, ctx) {
      const source = config.sources.find((s) => s.name === params.sourceName);
      if (!source) {
        return {
          content: [{ type: "text" as const, text: `Unknown source: ${params.sourceName}` }],
          details: {},
        };
      }

      log(`Processing source: ${source.name} (path=${source.path}, weight=${source.weight})`);

      if (!existsSync(source.path)) {
        log(`Source path does not exist: ${source.path} — skipping`);
        return {
          content: [{ type: "text" as const, text: `Source path does not exist: ${source.path} — skipping.` }],
          details: {},
        };
      }

      // Run pre-processing script
      let preprocessResult: any;
      try {
        const raw = execSync(
          `node "${scriptPath}" "${source.path}" "${source.name}"`,
          { encoding: "utf-8", timeout: 30_000 }
        );
        preprocessResult = JSON.parse(raw);
      } catch (e: any) {
        log(`Pre-processing failed: ${e.message}`);
        return {
          content: [{ type: "text" as const, text: `Pre-processing failed: ${e.message}` }],
          details: {},
        };
      }

      const { sessions } = preprocessResult;
      if (sessions.length === 0) {
        log("No new sessions to process");
        return {
          content: [{ type: "text" as const, text: "No new sessions to process." }],
          details: {},
        };
      }

      const index = loadIndex();
      const results: string[] = [];

      for (const session of sessions) {
        // For fully-compacted sessions with no conversation tail,
        // use the compaction summary directly
        if (session.compactionSummary && session.conversation.length === 0) {
          const summary = session.compactionSummary;
          saveSummary(config, source, session, summary);
          index[session.fileKey] = { lastTimestamp: session.latestTimestamp || new Date().toISOString() };
          results.push(`${session.sessionId.slice(0, 8)}: used compaction summary`);
          continue;
        }

        // Build prompt and ask the LLM to summarize
        const prompt = buildSummarizationPrompt(session, source.weight);

        // Return the prompt so the LLM can process it
        // The LLM will call session_memory_save with the result
        results.push(
          `Session ${session.sessionId.slice(0, 8)} needs summarization. ` +
          `Compaction: ${session.compactionSummary ? "yes" : "no"}, ` +
          `Conversation entries: ${session.conversation.length}`
        );

        // Store pending session info for the save tool
        pendingSessions.set(session.sessionId, { session, source });

        // Update index now (even before summarization completes)
        if (session.latestTimestamp) {
          index[session.fileKey] = { lastTimestamp: session.latestTimestamp };
        }
      }

      saveIndex(index);

      // If there are sessions to summarize, return the prompts
      if (pendingSessions.size > 0) {
        let response = `Found ${sessions.length} session(s) to process.\n\n`;
        for (const session of sessions) {
          if (session.compactionSummary && session.conversation.length === 0) continue;
          response += `### Session ${session.sessionId.slice(0, 8)} (${source.name})\n\n`;
          response += buildSummarizationPrompt(session, source.weight);
          response += `\n\n---\n\n`;
          response += `After summarizing, call the \`session_memory_save\` tool with the sessionId "${session.sessionId}" and the summary text (or "SKIP").\n\n`;
        }
        return {
          content: [{ type: "text" as const, text: response }],
          details: {},
        };
      }

      if (config.autoCommit) {
        gitCommitAndPush(config.memoryPath, `session-memory: summarize ${source.name}`);
      }

      return {
        content: [{ type: "text" as const, text: results.join("\n") }],
        details: {},
      };
    },
  });

  // Pending sessions awaiting LLM summarization
  const pendingSessions = new Map<string, { session: any; source: Source }>();

  // Tool for the LLM to save a summary after processing
  pi.registerTool({
    name: "session_memory_save",
    label: "Session Memory Save",
    description:
      "Save a session summary generated by the LLM. Called after session_memory_summarize provides session data.",
    parameters: {
      type: "object" as const,
      properties: {
        sessionId: {
          type: "string" as const,
          description: "Session ID to save the summary for",
        },
        summary: {
          type: "string" as const,
          description: 'The summary text, or "SKIP" if the session is not worth remembering',
        },
      },
      required: ["sessionId", "summary"],
    },
    async execute(_toolCallId, params: { sessionId: string; summary: string }) {
      const pending = pendingSessions.get(params.sessionId);
      if (!pending) {
        return {
          content: [{ type: "text" as const, text: `No pending session: ${params.sessionId}` }],
          details: {},
        };
      }

      const { session, source } = pending;
      pendingSessions.delete(params.sessionId);

      if (params.summary.trim() === "SKIP") {
        log(`Skipped session ${params.sessionId.slice(0, 8)} (below importance threshold)`);
        if (pendingSessions.size === 0 && config.autoCommit) {
          gitCommitAndPush(config.memoryPath, `session-memory: summarize ${source.name}`);
        }
        return {
          content: [{ type: "text" as const, text: `Skipped session ${params.sessionId.slice(0, 8)}` }],
          details: {},
        };
      }

      saveSummary(config, source, session, params.summary);
      log(`Saved summary for session ${params.sessionId.slice(0, 8)}`);

      if (pendingSessions.size === 0 && config.autoCommit) {
        gitCommitAndPush(config.memoryPath, `session-memory: summarize ${source.name}`);
      }

      return {
        content: [{ type: "text" as const, text: `Saved summary for session ${params.sessionId.slice(0, 8)}` }],
        details: {},
      };
    },
  });

  // Register the promote tool
  pi.registerTool({
    name: "session_memory_promote",
    label: "Session Memory Promote",
    description:
      "Read short-term memory and existing long-term memory, then ask the LLM to promote recurring patterns and decisions to long-term memory.",
    parameters: {
      type: "object" as const,
      properties: {},
    },
    async execute() {
      const shortTermPath = join(config.memoryPath, "short-term.md");
      const longTermPath = join(config.memoryPath, "long-term.md");

      const shortTerm = existsSync(shortTermPath)
        ? readFileSync(shortTermPath, "utf-8")
        : "";
      const longTerm = existsSync(longTermPath)
        ? readFileSync(longTermPath, "utf-8")
        : "";

      if (!shortTerm.trim()) {
        return {
          content: [{ type: "text" as const, text: "No short-term memory to promote." }],
          details: {},
        };
      }

      let prompt = "## Current long-term memory\n\n";
      prompt += longTerm || "(empty)\n";
      prompt += "\n\n## Recent short-term memory (session summaries)\n\n";
      prompt += shortTerm;
      prompt += "\n\n---\n\n";
      prompt += "Review the short-term session summaries above and the existing long-term memory.\n\n";
      prompt += "Produce an updated long-term memory file in markdown. Focus on:\n";
      prompt += "- User preferences and patterns\n";
      prompt += "- Architecture and technical decisions\n";
      prompt += "- Project knowledge\n";
      prompt += "- Corrections and lessons learned\n\n";
      prompt += "Rules:\n";
      prompt += "- Merge new knowledge with existing entries\n";
      prompt += "- If the user changed their mind, update (don't keep both)\n";
      prompt += "- Remove anything no longer relevant\n";
      prompt += "- Keep it concise and human-readable\n\n";
      prompt += "After generating the updated long-term memory, call `session_memory_save_long_term` with the full markdown content.";

      return {
        content: [{ type: "text" as const, text: prompt }],
        details: {},
      };
    },
  });

  // Tool to save the promoted long-term memory
  pi.registerTool({
    name: "session_memory_save_long_term",
    label: "Session Memory Save Long-Term",
    description: "Save the promoted long-term memory markdown content.",
    parameters: {
      type: "object" as const,
      properties: {
        content: {
          type: "string" as const,
          description: "The full long-term memory markdown content",
        },
      },
      required: ["content"],
    },
    async execute(_toolCallId, params: { content: string }) {
      const longTermPath = join(config.memoryPath, "long-term.md");
      writeFileSync(longTermPath, params.content + "\n");
      log("Updated long-term memory");

      // Archive old short-term entries
      archiveOldShortTerm(config);

      if (config.autoCommit) {
        gitCommitAndPush(config.memoryPath, "session-memory: promote to long-term");
      }

      return {
        content: [{ type: "text" as const, text: "Long-term memory updated." }],
        details: {},
      };
    },
  });

  // Register command for manual trigger
  pi.registerCommand("memory-summarize", {
    description: "Manually trigger session memory summarization for a source",
    handler: async (args, ctx) => {
      const sourceName = args?.trim();
      if (!sourceName) {
        ctx.ui.notify(
          `Available sources: ${config.sources.map((s) => s.name).join(", ")}`,
          "info"
        );
        return;
      }
      ctx.ui.notify(`Triggering summarization for source: ${sourceName}`, "info");
    },
  });

  pi.registerCommand("memory-status", {
    description: "Show session memory status",
    handler: async (_args, ctx) => {
      const index = loadIndex();
      const entries = Object.entries(index);
      let msg = `Session Memory Status\n`;
      msg += `Sources: ${config.sources.map((s) => s.name).join(", ")}\n`;
      msg += `Memory path: ${config.memoryPath}\n`;
      msg += `Tracked sessions: ${entries.length}\n`;
      for (const [key, val] of entries) {
        msg += `  ${key}: last=${val.lastTimestamp}\n`;
      }
      ctx.ui.notify(msg, "info");
    },
  });

  // Inject short-term memory into sessions
  pi.on("before_agent_start", async (event) => {
    const shortTermPath = join(config.memoryPath, "short-term.md");
    if (!existsSync(shortTermPath)) return;

    const shortTerm = readFileSync(shortTermPath, "utf-8").trim();
    if (!shortTerm) return;

    // Trim to maxSummaries (take last N sections separated by ---)
    const sections = shortTerm.split(/\n---\n/).filter((s) => s.trim());
    const maxSections = config.shortTerm.maxSummaries;
    const trimmed = sections.slice(-maxSections).join("\n---\n");

    return {
      systemPrompt:
        event.systemPrompt +
        "\n\n## Recent Activity (Short-Term Memory)\n\n" +
        "The following are summaries of recent sessions. Use this context to understand what the user has been working on recently.\n\n" +
        trimmed,
    };
  });
}

// --- Helpers ---

function saveSummary(config: Config, source: Source, session: any, summary: string) {
  const date = (session.sessionTimestamp || new Date().toISOString()).slice(0, 10);
  const idPrefix = session.sessionId.slice(0, 6);
  const filename = `${date}_${source.name}_${idPrefix}.md`;
  const filepath = join(INDEX_DIR, "sessions", filename);

  // Append to session summary file
  const timestamp = new Date().toISOString().slice(0, 19).replace("T", " ");
  const header = existsSync(filepath)
    ? `\n---\n\n### Update ${timestamp}\n\n`
    : `# Session Summary: ${source.name} / ${idPrefix}\n\nDate: ${date}\nSource: ${source.name}\n\n### Summary ${timestamp}\n\n`;

  const content = header + summary + "\n";

  if (existsSync(filepath)) {
    const existing = readFileSync(filepath, "utf-8");
    writeFileSync(filepath, existing + content);
  } else {
    writeFileSync(filepath, content);
  }

  // Also append to short-term.md
  const shortTermPath = join(config.memoryPath, "short-term.md");
  const shortTermEntry = `### ${source.name} / ${idPrefix} (${date})\n\n${summary}\n\n---\n`;
  if (existsSync(shortTermPath)) {
    const existing = readFileSync(shortTermPath, "utf-8");
    writeFileSync(shortTermPath, existing + "\n" + shortTermEntry);
  } else {
    writeFileSync(shortTermPath, `# Short-Term Memory\n\n${shortTermEntry}`);
  }
}

function archiveOldShortTerm(config: Config) {
  const shortTermPath = join(config.memoryPath, "short-term.md");
  if (!existsSync(shortTermPath)) return;

  const content = readFileSync(shortTermPath, "utf-8");
  const sections = content.split(/\n---\n/).filter((s) => s.trim());

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - config.shortTerm.retentionDays);
  const cutoffStr = cutoff.toISOString().slice(0, 10);

  const keep: string[] = [];
  const archive: string[] = [];

  for (const section of sections) {
    // Try to extract date from section header
    const dateMatch = section.match(/\((\d{4}-\d{2}-\d{2})\)/);
    if (dateMatch && dateMatch[1] < cutoffStr) {
      archive.push(section);
    } else {
      keep.push(section);
    }
  }

  if (archive.length > 0) {
    // Save archived entries
    const archivePath = join(
      config.memoryPath,
      "archive",
      `archived_${cutoffStr}.md`
    );
    writeFileSync(archivePath, archive.join("\n---\n") + "\n");

    // Rewrite short-term with only kept entries
    const header = "# Short-Term Memory\n\n";
    writeFileSync(shortTermPath, header + keep.join("\n---\n") + "\n");
  }
}
