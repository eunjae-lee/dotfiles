import { CustomEditor } from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type { ExtensionAPI, KeybindingsManager } from "@mariozechner/pi-coding-agent";

class MultilineEditor extends CustomEditor {
  private multilineMode = false;
  private readonly kb: KeybindingsManager;

  constructor(
    tui: ConstructorParameters<typeof CustomEditor>[0],
    theme: ConstructorParameters<typeof CustomEditor>[1],
    keybindings: KeybindingsManager,
  ) {
    super(tui, theme, keybindings);
    this.kb = keybindings;
  }

  handleInput(data: string): void {
    if (matchesKey(data, "ctrl+v")) {
      this.multilineMode = !this.multilineMode;
      this.tui.requestRender();
      return;
    }

    if (this.multilineMode && this.kb.matches(data, "tui.input.submit")) {
      super.handleInput("\n");
      return;
    }

    super.handleInput(data);
  }

  render(width: number): string[] {
    const lines = super.render(width);
    if (!this.multilineMode || lines.length === 0) return lines;

    const label = " MULTILINE ";
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
    ctx.ui.setEditorComponent((tui, theme, keybindings) => new MultilineEditor(tui, theme, keybindings));
  });
}
