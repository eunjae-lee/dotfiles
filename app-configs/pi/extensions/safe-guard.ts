/**
 * oh-pi Safe Guard Extension
 * 
 * Combines destructive command confirmation + protected paths in one extension.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export const DANGEROUS_PATTERNS = [
  /\brm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|.*-rf\b|.*--force\b)/,
  /\bsudo\s+rm\b/,
  /\b(DROP|TRUNCATE|DELETE\s+FROM)\b/i,
  /\bchmod\s+777\b/,
  /\bmkfs\b/,
  /\bdd\s+if=/,
  />\s*\/dev\/sd[a-z]/,
];

export const PROTECTED_PATHS = [".env", ".git/", "node_modules/", ".pi/", "id_rsa", ".ssh/"];

export default function (pi: ExtensionAPI) {
  // Session-wide allowances
  const allowedDangerousPatterns = new Set<string>();
  const allowedProtectedPaths = new Set<string>();

  // Reset allowances on new session
  pi.on("session_start", async () => {
    allowedDangerousPatterns.clear();
    allowedProtectedPaths.clear();
  });

  pi.on("tool_call", async (event, ctx) => {
    // Check bash commands for dangerous patterns
    if (event.toolName === "bash") {
      const cmd = (event.input as { command?: string }).command ?? "";
      const match = DANGEROUS_PATTERNS.find((p) => p.test(cmd));
      if (match && ctx.hasUI) {
        const patternKey = match.source;
        if (allowedDangerousPatterns.has(patternKey)) return;

        process.stderr.write("\x07"); // terminal bell
        const choice = await ctx.ui.select(`⚠️ Dangerous Command\nExecute: ${cmd}?`, [
          "Allow once",
          "Allow during this session",
          "Block",
        ]);
        if (choice === "Allow during this session") {
          allowedDangerousPatterns.add(patternKey);
          return;
        }
        if (choice === "Block" || choice === undefined) {
          return { block: true, reason: "Blocked by user" };
        }
      }
    }

    // Check write/edit for protected paths
    if (event.toolName === "write" || event.toolName === "edit") {
      const path = (event.input as { path?: string }).path ?? "";
      const hit = PROTECTED_PATHS.find((p) => path.includes(p));
      if (hit) {
        if (ctx.hasUI) {
          if (allowedProtectedPaths.has(hit)) return;

          process.stderr.write("\x07"); // terminal bell
          const choice = await ctx.ui.select(`🛡️ Protected Path\nAllow write to ${path}?`, [
            "Allow once",
            "Allow during this session",
            "Block",
          ]);
          if (choice === "Allow during this session") {
            allowedProtectedPaths.add(hit);
            return;
          }
          if (choice === "Block" || choice === undefined) {
            return { block: true, reason: `Protected path: ${hit}` };
          }
        } else {
          return { block: true, reason: `Protected path: ${hit}` };
        }
      }
    }
  });
}
