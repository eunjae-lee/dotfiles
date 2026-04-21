import os from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

type ClipboardResult = {
  text: string;
  source: string;
};

function normalizeClipboardText(text: string): string {
  return text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

async function tryCommand(
  pi: ExtensionAPI,
  command: string,
  args: string[],
  source: string,
): Promise<ClipboardResult | null> {
  try {
    const result = await pi.exec(command, args, { timeout: 5000 });
    if (result.code !== 0) return null;
    return {
      text: normalizeClipboardText(result.stdout),
      source,
    };
  } catch {
    return null;
  }
}

async function readClipboard(pi: ExtensionAPI): Promise<ClipboardResult | null> {
  const platform = os.platform();

  if (process.env.TERMUX_VERSION) {
    const result = await tryCommand(pi, "termux-clipboard-get", [], "termux-clipboard-get");
    if (result) return result;
  }

  if (platform === "darwin") {
    const result = await tryCommand(pi, "pbpaste", [], "pbpaste");
    if (result) return result;
  }

  if (platform === "win32") {
    const powershell = await tryCommand(
      pi,
      "powershell",
      ["-NoProfile", "-Command", "Get-Clipboard"],
      "powershell Get-Clipboard",
    );
    if (powershell) return powershell;

    const pwsh = await tryCommand(
      pi,
      "pwsh",
      ["-NoProfile", "-Command", "Get-Clipboard"],
      "pwsh Get-Clipboard",
    );
    if (pwsh) return pwsh;
  }

  const linuxCommands: Array<[string, string[], string]> = [
    ["wl-paste", ["--no-newline"], "wl-paste --no-newline"],
    ["xclip", ["-selection", "clipboard", "-o"], "xclip clipboard"],
    ["xsel", ["--clipboard", "--output"], "xsel clipboard"],
  ];

  for (const [command, args, source] of linuxCommands) {
    const result = await tryCommand(pi, command, args, source);
    if (result) return result;
  }

  return null;
}

function insertIntoEditor(ctx: ExtensionContext, text: string): void {
  const current = ctx.ui.getEditorText();
  ctx.ui.setEditorText(`${current}${text}`);
}

async function pasteClipboard(pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> {
  if (!ctx.hasUI) return;

  const clipboard = await readClipboard(pi);
  if (!clipboard) {
    ctx.ui.notify("Could not read clipboard text on this system.", "error")
    return;
  }

  if (clipboard.text.length === 0) {
    ctx.ui.notify("Clipboard is empty.", "warning");
    return;
  }

  ctx.ui.pasteToEditor(clipboard.text);
  ctx.ui.notify(`Pasted ${clipboard.text.length} chars from clipboard.`, "info");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("paste", {
    description: "Paste text from the system clipboard directly into the editor",
    handler: async (_args, ctx) => {
      await pasteClipboard(pi, ctx);
    },
  });

  pi.registerShortcut("ctrl+v", {
    description: "Paste text from the system clipboard into the editor",
    handler: async (ctx) => {
      await pasteClipboard(pi, ctx);
    },
  });
}
