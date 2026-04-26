import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { addDraft, type DraftScope } from "./store";
import { openDraftPicker } from "./picker";

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+s", {
    description: "Save current prompt as a draft",
    handler: async (ctx) => {
      if (!ctx.hasUI) return;

      const text = ctx.ui.getEditorText();
      if (!text.trim()) {
        ctx.ui.notify("Nothing to save", "info");
        return;
      }

      const choice = await ctx.ui.select("Save draft", [
        "Global draft",
        "Current directory draft",
        "Cancel",
      ]);

      let scope: DraftScope | undefined;
      if (choice === "Global draft") scope = "global";
      if (choice === "Current directory draft") scope = "cwd";
      if (!scope) return;

      try {
        await addDraft(scope, ctx.cwd, text);
        ctx.ui.setEditorText("");
        ctx.ui.notify(scope === "global" ? "Saved global draft" : "Saved current-directory draft", "info");
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Failed to save draft: ${message}`, "error");
      }
    },
  });

  pi.registerCommand("drafts", {
    description: "Open saved prompt drafts",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      try {
        await openDraftPicker(ctx);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Failed to open drafts: ${message}`, "error");
      }
    },
  });
}
