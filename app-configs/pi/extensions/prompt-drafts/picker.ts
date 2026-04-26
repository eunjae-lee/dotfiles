import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@mariozechner/pi-tui";
import { deleteDraft, listDrafts } from "./store";

type PickerResult =
  | { action: "load"; text: string }
  | { action: "close" };

function getPreview(text: string): string {
  const compact = text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .join(" ↵ ");
  return compact || "(empty draft)";
}

export async function openDraftPicker(ctx: ExtensionContext): Promise<void> {
  let drafts = await listDrafts(ctx.cwd);

  const result = await ctx.ui.custom<PickerResult>((tui, theme, _kb, done) => {
    let selected = 0;
    let scrollTop = 0;
    let deleting = false;
    let cachedWidth: number | undefined;
    let cachedLines: string[] | undefined;

    const visibleRows = 12;

    const clampSelection = () => {
      if (drafts.length === 0) {
        selected = 0;
        scrollTop = 0;
        return;
      }

      if (selected >= drafts.length) selected = drafts.length - 1;
      if (selected < 0) selected = 0;

      if (selected < scrollTop) scrollTop = selected;
      if (selected >= scrollTop + visibleRows) scrollTop = selected - visibleRows + 1;
      if (scrollTop < 0) scrollTop = 0;
    };

    const invalidate = () => {
      cachedWidth = undefined;
      cachedLines = undefined;
    };

    const requestRender = () => {
      invalidate();
      tui.requestRender();
    };

    const removeSelected = async () => {
      if (deleting || drafts.length === 0) return;
      deleting = true;
      requestRender();

      try {
        const draft = drafts[selected]!;
        await deleteDraft(draft.scope, ctx.cwd, draft.storageIndex);
        drafts = await listDrafts(ctx.cwd);
        clampSelection();
        ctx.ui.notify(`Deleted ${draft.scope} draft`, "info");
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Failed to delete draft: ${message}`, "error");
      } finally {
        deleting = false;
        requestRender();
      }
    };

    const render = (width: number): string[] => {
      if (cachedLines && cachedWidth === width) return cachedLines;

      const innerWidth = Math.max(20, width - 4);
      const content: string[] = [];
      const title = theme.fg("accent", theme.bold("Drafts"));
      content.push(truncateToWidth(title, innerWidth));
      content.push(truncateToWidth(theme.fg("dim", "cwd drafts first • enter load • delete remove • esc close"), innerWidth));
      content.push("");

      if (drafts.length === 0) {
        content.push(truncateToWidth(theme.fg("muted", "No drafts saved for this cwd or globally."), innerWidth));
      } else {
        clampSelection();
        const window = drafts.slice(scrollTop, scrollTop + visibleRows);
        for (let i = 0; i < window.length; i += 1) {
          const draft = window[i]!;
          const absoluteIndex = scrollTop + i;
          const isSelected = absoluteIndex === selected;
          const scopeLabel = draft.scope === "cwd" ? "[cwd]" : "[global]";
          const prefix = isSelected ? "› " : "  ";
          const preview = getPreview(draft.text);
          const text = `${prefix}${scopeLabel} ${preview}`;
          const truncated = truncateToWidth(text, innerWidth);
          const styled = isSelected
            ? theme.bg("selectedBg", theme.fg("accent", truncated))
            : theme.fg(draft.scope === "cwd" ? "text" : "muted", truncated);
          content.push(styled);
        }

        const hiddenAbove = scrollTop;
        const hiddenBelow = Math.max(0, drafts.length - (scrollTop + window.length));
        if (hiddenAbove > 0 || hiddenBelow > 0) {
          content.push("");
          content.push(
            truncateToWidth(
              theme.fg("dim", `${hiddenAbove > 0 ? `↑ ${hiddenAbove} more` : ""}${hiddenAbove > 0 && hiddenBelow > 0 ? " • " : ""}${hiddenBelow > 0 ? `↓ ${hiddenBelow} more` : ""}`),
              innerWidth,
            ),
          );
        }
      }

      if (deleting) {
        content.push("");
        content.push(truncateToWidth(theme.fg("warning", "Deleting draft..."), innerWidth));
      }

      const top = theme.fg("borderAccent", `╭${"─".repeat(innerWidth + 2)}╮`);
      const bottom = theme.fg("borderAccent", `╰${"─".repeat(innerWidth + 2)}╯`);
      const lines: string[] = [top];
      for (const line of content) {
        const padded = truncateToWidth(line, innerWidth);
        lines.push(theme.fg("borderAccent", "│") + ` ${padded.padEnd(innerWidth, " ")} ` + theme.fg("borderAccent", "│"));
      }
      lines.push(bottom);

      cachedWidth = width;
      cachedLines = lines;
      return lines;
    };

    return {
      render,
      invalidate,
      handleInput(data: string) {
        if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
          done({ action: "close" });
          return;
        }

        if (drafts.length === 0) {
          if (matchesKey(data, "enter")) done({ action: "close" });
          return;
        }

        if (matchesKey(data, "up") || data === "k") {
          selected -= 1;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "down") || data === "j") {
          selected += 1;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "pageUp")) {
          selected -= visibleRows;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "pageDown")) {
          selected += visibleRows;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "home")) {
          selected = 0;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "end")) {
          selected = drafts.length - 1;
          clampSelection();
          requestRender();
          return;
        }

        if (matchesKey(data, "delete") || matchesKey(data, "ctrl+d")) {
          void removeSelected();
          return;
        }

        if (matchesKey(data, "enter")) {
          done({ action: "load", text: drafts[selected]!.text });
        }
      },
    };
  }, {
    overlay: true,
    overlayOptions: {
      width: "75%",
      minWidth: 60,
      maxHeight: "70%",
      anchor: "center",
      margin: 1,
    },
  });

  if (!result || result.action !== "load") return;
  ctx.ui.setEditorText(result.text);
  ctx.ui.notify("Draft loaded", "info");
}
