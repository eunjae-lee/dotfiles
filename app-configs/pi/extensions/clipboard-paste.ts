import os from "node:os";
import { CustomEditor } from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type { ExtensionAPI, ExtensionContext, KeybindingsManager } from "@mariozechner/pi-coding-agent";

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

async function pasteClipboard(pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> {
  if (!ctx.hasUI) return;

  const clipboard = await readClipboard(pi);
  if (!clipboard) {
    ctx.ui.notify("Could not read clipboard text on this system.", "error");
    return;
  }

  if (clipboard.text.length === 0) {
    ctx.ui.notify("Clipboard is empty.", "warning");
    return;
  }

  ctx.ui.pasteToEditor(clipboard.text);
  ctx.ui.notify(`Pasted ${clipboard.text.length} chars from clipboard.`, "info");
}

class DictationEditor extends CustomEditor {
  private dictationMode = false;

  constructor(
    tui: ConstructorParameters<typeof CustomEditor>[0],
    theme: ConstructorParameters<typeof CustomEditor>[1],
    keybindings: KeybindingsManager,
  ) {
    super(tui, theme, keybindings);
  }

  handleInput(data: string): void {
    if (matchesKey(data, "ctrl+v")) {
      this.dictationMode = !this.dictationMode;
      this.tui.requestRender();
      return;
    }

    if (this.dictationMode && this.keybindings.matches(data, "tui.input.submit")) {
      super.handleInput("\n");
      return;
    }

    super.handleInput(data);
  }

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) return lines;

    const label = this.dictationMode ? " DICTATION " : " NORMAL ";
    const last = lines.length - 1;
    if (visibleWidth(lines[last]!) >= label.length) {
      lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
    }
    return lines;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;
    ctx.ui.setEditorComponent((tui, theme, keybindings) => new DictationEditor(tui, theme, keybindings));
  });

  pi.registerCommand("paste", {
    description: "Paste text from the system clipboard directly into the editor",
    handler: async (_args, ctx) => {
      await pasteClipboard(pi, ctx);
    },
  });
}
