import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type SupersetEventType = "Start" | "Stop" | "PermissionRequest";
type RuntimeState = "idle" | "running" | "awaiting_permission";

const DANGEROUS_BASH_PATTERNS = [
  /\brm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|.*-rf\b|.*--force\b)/,
  /\bsudo\b/,
  /\b(chmod|chown)\b/,
  /\bgit\s+push\s+(-f|--force|--force-with-lease)\b/,
];

const PROTECTED_PATH_PATTERNS = [".env", ".git/", ".ssh/", "id_rsa", "id_ed25519"];

function hasSupersetContext(): boolean {
  return Boolean(process.env.SUPERSET_TAB_ID);
}

function shouldAskPermission(event: { toolName: string; input: unknown }): boolean {
  if (event.toolName === "bash") {
    const command = (event.input as { command?: string } | undefined)?.command ?? "";
    return DANGEROUS_BASH_PATTERNS.some((pattern) => pattern.test(command));
  }

  if (event.toolName === "edit" || event.toolName === "write") {
    const path = (event.input as { path?: string } | undefined)?.path ?? "";
    return PROTECTED_PATH_PATTERNS.some((segment) => path.includes(segment));
  }

  return false;
}

async function notifySuperset(eventType: SupersetEventType): Promise<void> {
  if (!hasSupersetContext()) return;

  const port = process.env.SUPERSET_PORT || "51741";
  const params = new URLSearchParams({
    paneId: process.env.SUPERSET_PANE_ID || "",
    tabId: process.env.SUPERSET_TAB_ID || "",
    workspaceId: process.env.SUPERSET_WORKSPACE_ID || "",
    eventType,
    env: process.env.SUPERSET_ENV || "",
    version: process.env.SUPERSET_HOOK_VERSION || "",
  });

  try {
    await fetch(`http://127.0.0.1:${port}/hook/complete?${params.toString()}`, {
      method: "GET",
      signal: AbortSignal.timeout(1500),
    });
  } catch {
    // Never block pi on Superset integration failures.
  }
}

export default function (pi: ExtensionAPI) {
  let state: RuntimeState = "idle";
  let lastEvent: SupersetEventType | undefined;

  const emit = async (eventType: SupersetEventType, nextState: RuntimeState) => {
    if (!hasSupersetContext()) return;
    if (lastEvent === eventType && state === nextState) return;

    state = nextState;
    lastEvent = eventType;
    await notifySuperset(eventType);
  };

  pi.on("session_start", async () => {
    state = "idle";
    lastEvent = undefined;
  });

  pi.on("before_agent_start", async () => {
    await emit("Start", "running");
  });

  pi.on("agent_end", async () => {
    await emit("Stop", "idle");
  });

  pi.on("session_shutdown", async () => {
    await emit("Stop", "idle");
  });

  if (process.env.PI_SUPERSET_PERMISSION_GATE === "1") {
    pi.on("tool_call", async (event, ctx) => {
      if (!ctx.hasUI) return;
      if (!shouldAskPermission(event)) return;

      await emit("PermissionRequest", "awaiting_permission");

      const label = event.toolName === "bash" ? "Allow dangerous command?" : "Allow write to protected path?";
      const detail = JSON.stringify(event.input, null, 2);
      const ok = await ctx.ui.confirm(label, detail);

      if (!ok) {
        await emit("Stop", "idle");
        return { block: true, reason: "Blocked by user" };
      }

      await emit("Start", "running");
    });
  }
}
